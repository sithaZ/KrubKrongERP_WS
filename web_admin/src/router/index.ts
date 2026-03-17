import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import HomeView from '../views/HomeView.vue'


import DashboardView from '../views/DashboardView.vue'
import UsersView from '../views/UsersView.vue'
import CatalogView from '../views/CatalogView.vue'
import SettingsView from '../views/SettingsView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: LoginView
    },
    {
      
      path: '/',
      component: HomeView,
      children: [
        {
          
          path: '',
          redirect: '/dashboard'
        },
        {
         
          path: 'dashboard',
          name: 'dashboard',
          component: DashboardView
        },
        {
          
          path: 'staff',
          name: 'staff',
          component: UsersView
        },
        {
          
          path: 'catalog',
          name: 'catalog',
          component: CatalogView
        },
        {
          
          path: 'settings',
          name: 'settings',
          component: SettingsView
        }
      ]
    }
  ]
})

export default router