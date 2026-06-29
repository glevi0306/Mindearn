import { defineConfig } from 'vite'

export default defineConfig({
  // public/ holds _headers, robots.txt, site.webmanifest — copied to dist/ as-is
  publicDir: 'public',

  build: {
    rollupOptions: {
      input: {
        // Production pages only — preview/dev HTML files are excluded
        main:      'index.html',
        dashboard: 'dashboard.html',
        courses:   'courses.html',
        lesson:    'lesson.html',
        audio:     'audio.html',
        practice:  'practice.html',
        workbook:  'workbook.html',
        profile:   'profile.html',
        crm:       'crm.html',
        '404':     '404.html',
      }
    }
  }
})
