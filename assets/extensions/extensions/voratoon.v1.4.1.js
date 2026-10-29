// @ts-check
// Voratoon: talks to the site's own /api/proxy, which is gated by a `vt_proxy`
// cookie (set by the homepage) and a same-origin sec-fetch-site header.
(() => {
  const BASE = 'https://voratoon.co'
  const API = BASE + '/api/proxy'
  const HEADERS = {
    Accept: 'application/json',
    'Accept-Language': 'en-US,en;q=0.9,id;q=0.8',
    'sec-fetch-site': 'same-origin',
    Referer: BASE + '/',
  }

  // Sort value -> API sort/sortOrder.
  const SORTS = {
    latest: ['latest', 'desc'],
    newseries: ['created', 'desc'],
    bookmark: ['bookmarks', 'desc'],
    popular: ['popularity', 'desc'],
    rating: ['rating', 'desc'],
    az: ['title', 'asc'],
  }

  // Trailing promo pages: 998*, 999*, Marathon*. 000 is a real page.
  const PROMO = /\/(99[89](?!\d)|marath)[^/]*$/i

  /** @param {string} path */
  async function get(path) {
    const req = { url: API + path, headers: HEADERS }
    let res = await http.fetch(req)
    if (res.status === 403) {
      // Missing/expired vt_proxy cookie: the homepage sets it, the jar keeps it.
      await http.fetch({ url: BASE + '/' })
      res = await http.fetch(req)
    }
    let json = null
    try {
      json = JSON.parse(res.body)
    } catch (_) {}
    if (res.status < 200 || res.status >= 300) {
      const msg = json && (json.error || json.message || json.code)
      throw new Error(`${res.status} ${msg || 'HTTP error'}: ${path}`)
    }
    if (!json || typeof json !== 'object') throw new Error(`Invalid JSON: ${path}`)
    return json
  }

  const str = (v) => (v == null || String(v).trim() === '' ? null : String(v).trim())
  // Alternative titles: trimmed, without placeholders, the main title or repeats.
  // Sites separate them with `•`, `|`, `;`, ` / ` (not `1/2`) or line breaks, else
  // with `, `. Titles have commas too, so commas split only when nothing else does.
  const STRONG_SEP = /\s*[•|;\n]\s*|\s+\/\s+/
  const splitAlts = (v) => {
    const s = v == null ? '' : String(v)
    return s.split(STRONG_SEP.test(s) ? STRONG_SEP : /\s*,\s+/)
  }
  const NONE = /^(-|\?|n\/a|none|unknown|updating|tba|tbd|field kosong)$/i
  function altTitles(title, list) {
    const key = (t) => t.toLowerCase().replace(/[‘’`]/g, "'")
    const seen = new Set([key(String(title || '').replace(/\s+/g, ' ').trim())])
    const out = []
    for (const v of list || []) {
      // Also drops separators left at the ends (`Title ,`).
      const t = v == null ? '' : String(v).replace(/\s+/g, ' ').replace(/^[\s,;•|]+|[\s,;•|]+$/g, '')
      if (!t || NONE.test(t) || seen.has(key(t))) continue
      seen.add(key(t))
      out.push(t)
    }
    return out
  }
  const num = (v) => (v == null || v === '' || !isFinite(Number(v)) ? null : Number(v))
  const lower = (v) => (v ? String(v).trim().toLowerCase() : null)
  const enc = encodeURIComponent

  /** @returns {Series} */
  function toSeries(item) {
    const d = item.data || {}
    return {
      slug: String(d.slug),
      title: String(d.title),
      altTitles: altTitles(d.title, splitAlts(d.nativeTitle)),
      cover: str(d.coverImage),
      format: lower(d.format),
      status: lower(d.status),
      rating: num(d.rating),
      totalChapters: num(d.totalChapters),
    }
  }

  /** @param {string} slug @returns {Promise<Chapter[]>} */
  async function chapterList(slug) {
    const { data } = await get(`/series/${enc(slug)}/chapters`)
    return data
      .map((c) => ({
        number: Number(c.data && c.data.index != null ? c.data.index : c.chapterIndex),
        createdAt: str(c.createdAt),
      }))
      .filter((c) => isFinite(c.number))
      .sort((a, b) => b.number - a.number)
  }

  const ALL = { value: '', label: 'All' }

  // First value of a group, '' / missing = no filter.
  const pick = (f, key) => (f && f[key] && f[key][0]) || null

  defineExtension({
    async filters() {
      const { data } = await get('/genres')
      return [
        {
          key: 'sort',
          label: 'Sort',
          type: 'select',
          default: 'latest',
          options: [
            { value: 'latest', label: 'Latest update' },
            { value: 'newseries', label: 'New series' },
            { value: 'popular', label: 'Popular' },
            { value: 'rating', label: 'Top rated' },
            { value: 'bookmark', label: 'Most bookmarked' },
            { value: 'az', label: 'A–Z' },
          ],
        },
        {
          key: 'format',
          label: 'Format',
          type: 'select',
          quick: true,
          options: [
            ALL,
            { value: 'manhwa', label: 'Manhwa' },
            { value: 'manhua', label: 'Manhua' },
            { value: 'manga', label: 'Manga' },
            { value: 'mangatoon', label: 'Mangatoon' },
            { value: 'webtoon', label: 'Webtoon' },
          ],
        },
        {
          key: 'status',
          label: 'Status',
          type: 'select',
          options: [
            ALL,
            { value: 'ongoing', label: 'Ongoing' },
            { value: 'completed', label: 'Completed' },
            { value: 'hiatus', label: 'Hiatus' },
            { value: 'cancelled', label: 'Cancelled' },
          ],
        },
        {
          key: 'type',
          label: 'Type',
          type: 'select',
          options: [ALL, { value: 'project', label: 'Project' }, { value: 'mirror', label: 'Mirror' }],
        },
        {
          key: 'genre',
          label: 'Genre',
          type: 'multi',
          options: data
            .map((g) => ({ value: String(g.id), label: String(g.data && g.data.name) }))
            .sort((a, b) => (a.label.toLowerCase() < b.label.toLowerCase() ? -1 : 1)),
        },
      ]
    },
    home: { featured: { sort: ['newseries'] }, latest: { sort: ['latest'] } },

    async browse({ page, limit, query, filters }) {
      const [sortBy, sortOrder] = SORTS[pick(filters, 'sort') || 'latest'] || SORTS.latest
      const filter = ['status', 'format', 'type']
        .map((k) => pick(filters, k) && `${k}==${pick(filters, k)}`)
        .filter(Boolean)
        .join(';')
      const q = qs({
        page: page || 1,
        take: Math.min(Math.max(Number(limit) || 30, 1), 100),
        includeMeta: true,
        title: query ? query.trim().slice(0, 100) : null,
        sort: sortBy,
        sortOrder,
        filter,
        genreIds: ((filters && filters.genre) || []).filter(Boolean),
        takeChapter: 1,
      })
      const { data, meta } = await get('/series?' + q)
      return {
        items: data.map(toSeries),
        hasNext: !!meta && Number(meta.page) < Number(meta.lastPage),
      }
    },

    // Chapter pages are keyed by the chapter index: /series/<slug>/chapter/271.5
    webUrl(slug, number) {
      const series = `${BASE}/series/${enc(slug)}`
      return number == null ? series : `${series}/chapter/${enc(String(number))}`
    },

    async series(slug) {
      const { data: item } = await get(`/series/${enc(slug)}`)
      const d = item.data || {}
      return {
        ...toSeries(item),
        nativeTitle: altTitles(d.title, splitAlts(d.nativeTitle))[0] || null,
        altTitles: altTitles(d.title, splitAlts(d.nativeTitle)),
        releaseDate: str(d.releaseDate),
        author: str(d.author),
        synopsis: str(d.synopsis),
        genres: (d.genres || []).map((g) => ({ id: String(g.id), name: String(g.data && g.data.name) })),
      }
    },

    chapters: chapterList,

    async chapter(slug, number) {
      const n = Number(number)
      const [{ data: c }, list] = await Promise.all([
        get(`/series/${enc(slug)}/chapters/${enc(String(n))}`),
        chapterList(slug),
      ])
      // List is newest first: the next chapter sits one position earlier.
      const i = list.findIndex((x) => x.number === n)
      const d = c.data || {}
      return {
        number: n,
        title: str(d.title),
        prev: i >= 0 && i + 1 < list.length ? list[i + 1].number : null,
        next: i > 0 ? list[i - 1].number : null,
        images: (d.images || []).map(String).filter((u) => !PROMO.test(u.split('?')[0])),
      }
    },
  })
})()
