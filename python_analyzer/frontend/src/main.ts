import { createApp } from 'vue'
import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import {
  faBolt,
  faChartLine,
  faChartPie,
  faCalendarDays,
  faMagnifyingGlass,
  faClock,
  faArrowsRotate,
  faRotate,
  faTags,
  faTrophy,
  faCalendarDay,
} from '@fortawesome/free-solid-svg-icons'

import App from './App.vue'
import router from './router'

library.add(
  faBolt,
  faChartLine,
  faChartPie,
  faCalendarDays,
  faMagnifyingGlass,
  faClock,
  faArrowsRotate,
  faRotate,
  faTags,
  faTrophy,
  faCalendarDay,
)

const app = createApp(App)

app.component('FontAwesomeIcon', FontAwesomeIcon)
app.use(router)

app.mount('#app')
