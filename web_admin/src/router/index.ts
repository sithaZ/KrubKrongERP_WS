import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import HomeView from '../views/HomeView.vue'


import DashboardView from '../views/DashboardView.vue'
import UsersView from '../views/UsersView.vue'
import CatalogView from '../views/CatalogView.vue'
import SettingsView from '../views/SettingsView.vue'
import AttendanceView from '../views/AttendanceView.vue';
import PayrollView from '../views/PayrollView.vue';

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
        path: 'attendance',
        name: 'attendance',
        component: AttendanceView,
        },
        {
         
          path: 'dashboard',
          name: 'dashboard',
          component: DashboardView
        },
          {
      path: 'payroll',
      name: 'payroll',
      component: PayrollView,
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

router.beforeEach((to, _from, next) => {
  const token = localStorage.getItem('token')
  const role = localStorage.getItem('role')
  const isLoginRoute = to.path === '/login'

  if (!token && !isLoginRoute) {
    next('/login')
    return
  }

  if (token && isLoginRoute && role === 'ADMIN') {
    next('/dashboard')
    return
  }

  if (token && !isLoginRoute && role !== 'ADMIN') {
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
