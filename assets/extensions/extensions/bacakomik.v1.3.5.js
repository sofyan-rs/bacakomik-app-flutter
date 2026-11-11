// @ts-check
// BacaKomik: thin wrapper over our own JSON API, which already speaks the contract.
(() => {
  const BASE = 'https://api-bacakomik.kurodev.org'
  const SITE = 'https://bacakomik.my'

  /** @param {string} path */
  async function get(path) {
    const res = await http.fetch({ url: BASE + path, headers: { Accept: 'application/json' } })
    let json = null
    try {
      json = JSON.parse(res.body)
    } catch (_) {}
    if (res.status < 200 || res.status >= 300) {
      throw new Error(`${res.status} ${(json && json.error) || 'HTTP error'}: ${path}`)
    }
    if (!json || typeof json !== 'object') throw new Error(`Invalid JSON: ${path}`)
    return json
  }

  const str = (v) => (v == null || v === '' ? null : String(v))
  const num = (v) => (v == null || v === '' || !isFinite(Number(v)) ? null : Number(v))
  const lower = (v) => (v ? String(v).toLowerCase() : null)
  const enc = encodeURIComponent

  /** @returns {Series} */
  function toSeries(d) {
    return {
      slug: String(d.slug),
      title: String(d.title),
      // The API has one alternative title.
      altTitles: str(d.nativeTitle) && d.nativeTitle.trim() !== d.title ? [d.nativeTitle.trim()] : [],
      cover: str(d.cover),
      format: lower(d.format),
      status: lower(d.status),
      rating: num(d.rating),
      totalChapters: num(d.totalChapters),
    }
  }

  // A chapter is a WordPress post, and the API hands us its id. Its permalink
  // and image list come straight from WordPress REST, so we never guess the
  // site's slugs or link shapes (`eleceed-chapter-1`, `<slug>-2`, `179-end`).
  /** @param {number} id @returns {Promise<{ link: string, categories: number[], images: string[] } | null>} */
  async function post(id) {
    try {
      const res = await http.fetch({ url: `${SITE}/wp-json/wp/v2/posts/${id}?_fields=link,categories,content` })
      if (res.status !== 200) return null
      const d = JSON.parse(res.body)
      const images = []
      const re = /<img[^>]+?src="(https?:\/\/[^"]+)"/g
      let m
      while ((m = re.exec((d.content && d.content.rendered) || ''))) images.push(m[1].replace(/ /g, '%20'))
      return { link: String(d.link || ''), categories: d.categories || [], images }
    } catch (_) {
      return null
    }
  }

  // Images in a chapter page's reader block, [] when the page has none.
  /** @param {string} url @returns {Promise<string[]>} */
  async function pageImages(url) {
    if (!url) return []
    try {
      const res = await http.fetch({ url })
      const body = res.body || ''
      const start = body.indexOf('id="chimg')
      if (res.status !== 200 || start < 0) return []
      const end = body.indexOf('<script', start)
      const reader = body.slice(start, end < 0 ? body.length : end)
      const images = []
      const re = /data-lazy-src="(https?:\/\/[^"]+)"/g
      let m
      // Folders can hold spaces (`179 End`).
      while ((m = re.exec(reader))) images.push(m[1].replace(/ /g, '%20'))
      return images
    } catch (_) {
      return []
    }
  }

  /** @param {string} url */
  const host = (url) => (url.match(/^https?:\/\/([^\/]+)/) || [])[1] || ''

  // The post's own images name an origin host (`master.komikcdn.me`) that answers
  // 403, and old series point at hosts that serve a "Baca Komik Ini Di
  // BACAKOMIK.CO" placeholder. The chapter page swaps in the live hosts, so read
  // the images there. When the permalink is broken (`<slug>/` can land on the
  // series archive), keep the post's images but borrow the hosts a sibling
  // chapter's page uses. [] = no luck.
  /** @param {number} id @returns {Promise<string[]>} */
  async function chapterImages(id) {
    const p = await post(id)
    if (!p) return []
    const page = await pageImages(p.link)
    if (page.length || !p.images.length || !p.categories.length) return page
    try {
      const res = await http.fetch({
        url: `${SITE}/wp-json/wp/v2/posts?categories=${p.categories[0]}&exclude=${id}&per_page=3&_fields=link`,
      })
      for (const s of res.status === 200 ? JSON.parse(res.body) : []) {
        const hosts = [...new Set((await pageImages(String(s.link || ''))).map(host))]
        if (!hosts.length) continue
        return p.images.map((u, i) =>
          hosts.includes(host(u)) ? u : u.replace(/^(https?:\/\/)[^\/]+/, `$1${hosts[i % hosts.length]}`),
        )
      }
    } catch (_) {}
    return []
  }

  // The chapter's page on the site, or the series page when it cannot be found.
  /** @param {string} slug @param {number} number */
  async function chapterUrl(slug, number) {
    const series = `${SITE}/komik/${enc(slug)}/`
    try {
      const { data: d } = await get(`/series/${enc(slug)}/chapters/${enc(String(number))}`)
      const p = d.id == null ? null : await post(d.id)
      if (p && p.link) return p.link
    } catch (_) {}
    return series
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
            { value: 'az', label: 'A–Z' },
            { value: 'za', label: 'Z–A' },
          ],
        },
        {
          key: 'format',
          label: 'Format',
          type: 'select',
          quick: true,
          options: [
            ALL,
            { value: 'manga', label: 'Manga' },
            { value: 'manhwa', label: 'Manhwa' },
            { value: 'manhua', label: 'Manhua' },
            { value: 'comic', label: 'Comic' },
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
          options: data.map((g) => ({ value: String(g.id), label: String(g.name) })),
        },
      ]
    },
    home: { featured: { sort: ['newseries'] }, latest: { sort: ['latest'] } },

    async browse({ page, limit, query, filters }) {
      const genres = ((filters && filters.genre) || []).filter(Boolean)
      const q = qs({
        page: page || 1,
        limit,
        q: query ? query.trim() : null,
        sort: pick(filters, 'sort'),
        status: pick(filters, 'status'),
        format: pick(filters, 'format'),
        type: pick(filters, 'type'),
        genre: genres.length ? genres.join(',') : null,
      })
      const { data, meta } = await get('/series' + (q ? '?' + q : ''))
      return {
        items: data.map(toSeries),
        hasNext: !!meta && meta.page < meta.lastPage,
      }
    },

    webUrl(slug, number) {
      return number == null ? `${SITE}/komik/${enc(slug)}/` : chapterUrl(slug, Number(number))
    },

    async series(slug) {
      const { data: d } = await get(`/series/${enc(slug)}`)
      return {
        ...toSeries(d),
        nativeTitle: str(d.nativeTitle),
        releaseDate: str(d.releaseDate),
        author: str(d.author),
        synopsis: str(d.synopsis),
        genres: (d.genres || []).map((g) => ({ id: String(g.id), name: String(g.name) })),
      }
    },

    async chapters(slug) {
      const { data } = await get(`/series/${enc(slug)}/chapters`)
      return data.map((c) => ({ number: Number(c.number), createdAt: str(c.createdAt) }))
    },

    async chapter(slug, number) {
      const { data: d } = await get(`/series/${enc(slug)}/chapters/${enc(String(number))}`)
      const site = d.id == null ? [] : await chapterImages(Number(d.id))
      return {
        number: Number(d.number),
        title: str(d.title),
        prev: num(d.prev),
        next: num(d.next),
        images: site.length ? site : (d.images || []).map(String),
      }
    },
  })
})()
