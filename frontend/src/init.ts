import { createApp } from 'vue';
import App from './App.vue';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import "dayjs/locale/fr";
import './css/main.css';
import { createRouter, createWebHistory } from 'vue-router';
import { createPinia } from "pinia";


(async () => {
    dayjs.locale(navigator.language || navigator.languages[0]);
    dayjs.extend(relativeTime);
})();

const app = createApp(App)

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: () => import('./components/pages/home/Home.vue') },
  ]
})
app.use(router);

const pinia = createPinia()
app.use(pinia)

app.mount('#app');