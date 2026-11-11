// @ts-check
// Voratoon: the backend (api.voratoon.com) answers with encrypted bodies. The
// site reads it through its Next.js server action `runApiCalls`, which takes a
// batch of API calls and returns their decrypted results as an RSC stream.
(() => {
  const BASE = 'https://voratoon.co'
  // Action ids change with each deploy; findAction() reads the current one
  // from the site's scripts when this one stops working.
  const DEFAULT_ACTION = '40bf0667ece0fafa286a16f59082816b0072398611'
  const ACTION_KEY = 'runApiCalls'

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

  // UTF-8 byte length of one code point: RSC text rows give their size in bytes.
  const utf8Len = (cp) => (cp < 0x80 ? 1 : cp < 0x800 ? 2 : cp < 0x10000 ? 3 : 4)

  // Parses a React Flight (RSC) stream and returns row 0 with `$<id>` refs
  // resolved. Rows are `<id>:<json>\n`, or `<id>:T<hex bytes>,<text>` with no
  // newline after the text.
  /** @param {string} body */
  function parseFlight(body) {
    /** @type {Record<string, any>} */
    const rows = {}
    let i = 0
    while (i < body.length) {
      const colon = body.indexOf(':', i)
      if (colon < 0) break
      const id = body.slice(i, colon).trim()
      if (body[colon + 1] === 'T') {
        const comma = body.indexOf(',', colon)
        let left = parseInt(body.slice(colon + 2, comma), 16)
        let j = comma + 1
        while (left > 0 && j < body.length) {
          const cp = /** @type {number} */ (body.codePointAt(j))
          left -= utf8Len(cp)
          j += cp > 0xffff ? 2 : 1
        }
        rows[id] = body.slice(comma + 1, j)
        i = j
      } else {
        let nl = body.indexOf('\n', colon)
        if (nl < 0) nl = body.length
        const line = body.slice(colon + 1, nl)
        try {
          rows[id] = JSON.parse(line)
        } catch (_) {
          rows[id] = line
        }
        i = nl + 1
      }
    }
    const done = new Map()
    const resolve = (v) => {
      if (typeof v === 'string') {
        if (v[0] !== '$') return v
        if (v[1] === '$') return v.slice(1)
        if (v === '$undefined') return undefined
        const ref = /^\$@?([0-9a-f]+)$/.exec(v)
        if (ref) return row(ref[1])
        if (v[1] === 'D') return v.slice(2)
        return v
      }
      if (Array.isArray(v)) return v.map(resolve)
      if (v && typeof v === 'object') {
        /** @type {Record<string, any>} */
        const o = {}
        for (const k of Object.keys(v)) o[k] = resolve(v[k])
        return o
      }
      return v
    }
    const row = (id) => {
      if (!done.has(id)) {
        done.set(id, null)
        done.set(id, resolve(rows[id]))
      }
      return done.get(id)
    }
    return row('0')
  }

  // Reads the current runApiCalls id from the site's scripts.
  async function findAction() {
    const home = await http.fetch({ url: BASE + '/' })
    const found = home.body.match(/\/_next\/static\/chunks\/[^"'\s<>]+?\.js[^"'\s<>]*/g) || []
    const srcs = [...new Set(found.map((s) => s.replace(/&amp;/g, '&')))]
    // The client API module has been in chunk 6951; look there first.
    srcs.sort((a, b) => Number(/\/6951-/.test(b)) - Number(/\/6951-/.test(a)))
    for (const src of srcs) {
      const js = await http.fetch({ url: BASE + src })
      const m = /"([0-9a-f]{40,})",[^"]{0,160}"runApiCalls"/.exec(js.body)
      if (m) {
        await storage.set(ACTION_KEY, m[1])
        return m[1]
      }
    }
    throw new Error('runApiCalls action not found on ' + BASE)
  }

  /** @type {string | null} */
  let action = null

  /** @param {string} id @param {unknown[]} calls */
  function postAction(id, calls) {
    return http.fetch({
      url: BASE + '/',
      method: 'POST',
      headers: {
        Accept: 'text/x-component',
        'Content-Type': 'text/plain;charset=UTF-8',
        'Next-Action': id,
        Origin: BASE,
        Referer: BASE + '/',
      },
      body: JSON.stringify([calls]),
    })
  }

  // Cleans a query object: drops null/''/empty arrays, as the site does.
  function cleanQuery(q) {
    if (!q) return undefined
    /** @type {Record<string, any>} */
    const out = {}
    for (const k of Object.keys(q)) {
      const v = Array.isArray(q[k]) ? q[k].filter((x) => x != null && x !== '').map(String) : q[k]
      if (v == null || v === '' || (Array.isArray(v) && !v.length)) continue
      out[k] = Array.isArray(v) ? v : String(v)
    }
    return out
  }

  /**
   * Runs API calls in one server action request; returns each `data` envelope.
   * @param {{ path: string, query?: Record<string, any> }[]} list
   */
  async function api(list) {
    const calls = list.map((c) => ({ path: c.path, method: 'GET', query: cleanQuery(c.query), token: null }))
    if (!action) action = (await storage.get(ACTION_KEY)) || DEFAULT_ACTION
    let res = await postAction(action, calls)
    if (res.status === 404 && res.headers['x-nextjs-action-not-found']) {
      action = await findAction()
      res = await postAction(action, calls)
    }
    if (res.status < 200 || res.status >= 300) throw new Error(`${res.status} HTTP error: ${list[0].path}`)
    const root = parseFlight(res.body)
    const results = root && root.a
    if (!Array.isArray(results)) throw new Error(`Invalid response: ${list[0].path}`)
    return results.map((r, i) => {
      const path = list[i].path
      if (!r || !r.ok) {
        const p = (r && r.payload) || {}
        const msg = p.error || p.message || (r && r.message) || 'API error'
        throw new Error(`${(r && r.status) || 'ERR'} ${msg}: ${path}`)
      }
      const env = r.envelope
      if (!env || typeof env !== 'object') throw new Error(`Invalid JSON: ${path}`)
      return env
    })
  }

  /** @param {string} path @param {Record<string, any>} [query] */
  const get = async (path, query) => (await api([{ path, query }]))[0]

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

  const chaptersPath = (slug) => `/series/${enc(slug)}/chapters`

  /** @returns {Chapter[]} */
  function toChapters(data) {
    return (data || [])
      .map((c) => ({
        number: Number(c.data && c.data.index != null ? c.data.index : c.chapterIndex),
        createdAt: str(c.createdAt),
      }))
      .filter((c) => isFinite(c.number))
      .sort((a, b) => b.number - a.number)
  }

  /** @param {string} slug @returns {Promise<Chapter[]>} */
  async function chapterList(slug) {
    return toChapters((await get(chaptersPath(slug))).data)
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
      const { data, meta } = await get('/series', {
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
      const [{ data: c }, all] = await api([
        { path: `${chaptersPath(slug)}/${enc(String(n))}` },
        { path: chaptersPath(slug) },
      ])
      const list = toChapters(all.data)
      // List is newest first: the next chapter sits one position earlier.
      const i = list.findIndex((x) => x.number === n)
      const d = c.data || {}
      return {
        number: n,
        title: str(d.title),
        prev: i >= 0 && i + 1 < list.length ? list[i + 1].number : null,
        next: i > 0 ? list[i - 1].number : null,
        images: (d.images || []).map(String).filter((u) => !PROMO.test(u.split('?')[0])),
        // cdn.voratoon.com answers 403 without the site as Referer.
        headers: { Referer: BASE + '/' },
      }
    },
  })
})()
