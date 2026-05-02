<template>
  <div class="horizontal-layout">
    <header class="top-header">
      <div class="logo-container">
        <div class="logo-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12 2L2 7h20L12 2z"/>
            <path d="M2 17l10 5 10-5"/>
            <path d="M2 12l10 5 10-5"/>
          </svg>
        </div>
        <h2>KrubKrong ERP</h2>
      </div>

      <div class="header-right">
        <div class="date-display">{{ currentDate }}</div>

        <div class="user-profile">
          <div class="avatar">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
          </div>
          <div class="user-info">
            <span class="role">{{ displayRole }}</span>
            <span class="name">{{ displayName }}</span>
          </div>
        </div>

        <button @click="handleLogout" class="logout-btn" title="Logout">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
            <polyline points="16 17 21 12 16 7"/>
            <line x1="21" x2="9" y1="12" y2="12"/>
          </svg>
        </button>
      </div>
    </header>

    <nav class="top-nav">
      <div class="nav-container">
        <router-link to="/dashboard" active-class="active">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect width="7" height="9" x="3" y="3" rx="1"/>
            <rect width="7" height="5" x="14" y="3" rx="1"/>
            <rect width="7" height="9" x="14" y="12" rx="1"/>
            <rect width="7" height="5" x="3" y="16" rx="1"/>
          </svg>
          Dashboard
        </router-link>

        <router-link to="/staff" active-class="active">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M22 21v-2a4 4 0 0 0-3-3.87"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
          </svg>
          Employees
        </router-link>

        <router-link to="/attendance" active-class="active">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M8 2v4"/>
            <path d="M16 2v4"/>
            <rect width="18" height="18" x="3" y="4" rx="2"/>
            <path d="M3 10h18"/>
          </svg>
          Attendance
        </router-link>
        
        <router-link to="/payroll" active-class="active">
        <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="2" y="5" width="20" height="14" rx="2"/>
        <path d="M2 10h20"/>
        </svg>
         Payroll
        </router-link>
      
        <router-link to="/catalog" active-class="active">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="m7.5 4.27 9 5.15"/>
            <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/>
            <path d="m3.3 7 8.7 5 8.7-5"/>
            <path d="M12 22V12"/>
          </svg>
          Catalog
        </router-link>

        <router-link to="/settings" active-class="active">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/>
            <circle cx="12" cy="12" r="3"/>
          </svg>
          Settings
        </router-link>
      </div>
    </nav>
  <main class="main-content">
  <router-view v-slot="{ Component }">
    <transition name="page-slide" mode="out-in">
      <component :is="Component" />
    </transition>
  </router-view>
  </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const displayName = ref('Admin User');
const displayRole = ref('Administrator');

const currentDate = ref(
  new Intl.DateTimeFormat('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date()),
);

onMounted(() => {
  const token = localStorage.getItem('token');
  const role = localStorage.getItem('role');

  if (!token || role !== 'ADMIN') {
    router.push('/login');
    return;
  }

  displayName.value = localStorage.getItem('username') || 'Admin User';
});

const handleLogout = () => {
  localStorage.removeItem('token');
  localStorage.removeItem('role');
  localStorage.removeItem('access_token');
  localStorage.removeItem('user_role');
  localStorage.removeItem('username');
  router.push('/login');
};
</script>

<style scoped>
.horizontal-layout {
  --primary: #283375;
  --primary-hover: #1a2254;
  --secondary: #4b6bb3;
  --accent: #74a7e6;
  --bg-main: #f4f6f9;
  --text-main: #111827;
  --text-muted: #64748b;
  --border-color: #e5e7eb;

  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background-color: var(--bg-main);
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}


.page-slide-enter-active,
.page-slide-leave-active {
  transition: opacity 0.22s ease, transform 0.22s ease;
}

.page-slide-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

.page-slide-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}
.top-header {
  background-color: var(--primary);
  color: white;
  padding: 0 2.5rem;
  min-height: 70px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  z-index: 10;
}

.logo-container {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-icon {
  background: linear-gradient(135deg, var(--accent) 0%, var(--secondary) 100%);
  padding: 8px;
  border-radius: 10px;
  display: flex;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
  color: white;
}

.logo-container h2 {
  font-size: 1.25rem;
  font-weight: 800;
  margin: 0;
  letter-spacing: 0.5px;
  color: #ffffff;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.date-display {
  font-size: 0.85rem;
  color: #e0e7ff;
  display: none;
}

@media (min-width: 768px) {
  .date-display {
    display: block;
  }
}

.user-profile {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 6px 12px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
}

.avatar {
  background-color: #eef2ff;
  color: var(--primary);
  padding: 6px;
  border-radius: 50%;
  display: flex;
}

.user-info {
  display: flex;
  flex-direction: column;
}

.role {
  font-size: 0.65rem;
  text-transform: uppercase;
  color: var(--accent);
  font-weight: 700;
  letter-spacing: 0.5px;
}

.name {
  font-size: 0.85rem;
  font-weight: 600;
  color: #ffffff;
}

.logout-btn {
  background: transparent;
  color: #f87171;
  border: 1px solid rgba(248, 113, 113, 0.3);
  padding: 8px;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.logout-btn:hover {
  background: rgba(248, 113, 113, 0.1);
  color: #ff0000;
}

.top-nav {
  background-color: white;
  border-bottom: 1px solid var(--border-color);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
}

.nav-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 2rem;
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  gap: 1.25rem;
}

.top-nav a {
  color: var(--text-muted);
  text-decoration: none;
  padding: 1rem 0;
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  font-size: 0.95rem;
  transition: all 0.2s ease;
  border-bottom: 3px solid transparent;
  white-space: nowrap;
}

.top-nav a:hover {
  color: var(--primary);
}

.top-nav a.active {
  color: var(--primary);
  border-bottom: 3px solid var(--primary);
}

.menu-icon {
  opacity: 0.8;
}

.top-nav a.active .menu-icon {
  opacity: 1;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  overflow-y: auto;
}

.main-content :deep(.page-shell) {
  width: min(1440px, 100%);
}

@media (max-width: 900px) {
  .top-header {
    padding: 1rem;
    flex-wrap: wrap;
    gap: 1rem;
    height: auto;
  }

  .header-right {
    width: 100%;
    justify-content: space-between;
  }

  .nav-container {
    justify-content: flex-start;
    padding: 0 1rem;
    gap: 1rem;
  }

  .top-nav a {
    font-size: 0.9rem;
    padding: 0.9rem 0;
  }
}
</style>
