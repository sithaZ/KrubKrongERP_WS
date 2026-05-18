import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import HomeView from '../views/HomeView.vue'
import DashboardView from '../views/DashboardView.vue'
import CatalogView from '../views/CatalogView.vue'
import SettingsView from '../views/SettingsView.vue'
import SubscriptionsView from '../views/SubscriptionsView.vue'
import ShopsView from '../views/ShopsView.vue'
import ManagersView from '../views/ManagersView.vue'

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
          path: 'shops',
          name: 'shops',
          component: ShopsView
        },
        {
          path: 'managers',
          name: 'managers',
          component: ManagersView
        },
        {
         
          path: 'dashboard',
          name: 'dashboard',
          component: DashboardView
        },
        {
          path: 'subscriptions',
          name: 'subscriptions',
          component: SubscriptionsView,
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
        },
        {
          path: ':pathMatch(.*)*',
          redirect: '/dashboard'
        }
      ]
    }
  ]
})

router.beforeEach((to, _from, next) => {
  const token = localStorage.getItem('token')
  const role = localStorage.getItem('role')
  const isLoginRoute = to.path === '/login'
  const isAdmin = role === 'ADMIN'

  if (!token && !isLoginRoute) {
    next('/login')
    return
  }

  if (token && isLoginRoute && isAdmin) {
    next('/dashboard')
    return
  }

  if (token && !isLoginRoute && !isAdmin) {
    localStorage.removeItem('token')
    localStorage.removeItem('role')
    localStorage.removeItem('access_token')
    localStorage.removeItem('user_role')
    localStorage.removeItem('username')
    next('/login')
    return
  }

  next()
})

export default router
