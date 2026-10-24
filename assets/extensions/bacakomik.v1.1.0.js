// @ts-check
// BacaKomik: thin wrapper over our own JSON API, which already speaks the contract.
(() => {
  const BASE = 'https://api-bacakomik.kurodev.org'

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
      cover: str(d.cover),
      format: lower(d.format),
      status: lower(d.status),
      rating: num(d.rating),
      totalChapters: num(d.totalChapters),
    }
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

    webUrl(slug) {
      return `https://bacakomik.my/komik/${enc(slug)}/`
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
      return {
        number: Number(d.number),
        title: str(d.title),
        prev: num(d.prev),
        next: num(d.next),
        images: (d.images || []).map(String),
      }
    },
  })
})()
