<template>
  <div class="dashboard-layout">
    <aside class="sidebar">
      <div class="logo-container">
        <div class="logo-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7h20L12 2z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
        </div>
        <h2>KrubKrong ERP</h2>
      </div>

      <nav class="menu">
        <a href="#" :class="{ active: activeTab === 'dashboard' }" @click.prevent="activeTab = 'dashboard'">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>
          Dashboard Overview
        </a>
        <a href="#" :class="{ active: activeTab === 'users' }" @click.prevent="activeTab = 'users'">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          User Management
        </a>
        <a href="#" :class="{ active: activeTab === 'catalog' }" @click.prevent="activeTab = 'catalog'">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></svg>
          Product Catalog
        </a>
        <a href="#" :class="{ active: activeTab === 'settings' }" @click.prevent="activeTab = 'settings'">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>
          System Settings
        </a>
      </nav>

      <div class="sidebar-footer">
        <button @click="handleLogout" class="logout-btn">
          <svg class="menu-icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
          Secure Logout
        </button>
      </div>
    </aside>

    <main class="main-content">
      <header class="top-header">
        <div class="header-left">
          <h1>System Overview</h1>
          <p class="date-display">{{ currentDate }}</p>
        </div>
        <div class="user-profile">
          <div class="avatar">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          </div>
          <div class="user-info">
            <span class="role">Administrator</span>
            <span class="name">Admin User</span>
          </div>
        </div>
      </header>

      <section class="content-area">
        <div class="welcome-card">
          <div class="welcome-text">
            <h2>Welcome back to Nexus ERP</h2>
            <p>Here is what's happening with your business today.</p>
          </div>
          <button class="action-btn">+ New Entry</button>
        </div>

        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-header">
              <h3>Total Sales</h3>
              <div class="icon-box navy"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg></div>
            </div>
            <p class="stat-number">$0.00</p>
            <p class="stat-trend neutral">Waiting for data...</p>
          </div>

          <div class="stat-card">
            <div class="stat-header">
              <h3>Total Products</h3>
              <div class="icon-box ocean"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="16" x="4" y="4" rx="2" ry="2"/><rect width="6" height="6" x="9" y="9" rx="1" ry="1"/></svg></div>
            </div>
            <p class="stat-number">--</p>
            <p class="stat-trend neutral">Waiting for data...</p>
          </div>

          <div class="stat-card">
            <div class="stat-header">
              <h3>Active Employees</h3>
              <div class="icon-box emerald"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></div>
            </div>
            <p class="stat-number">--</p>
            <p class="stat-trend neutral">Waiting for data...</p>
          </div>

          <div class="stat-card">
            <div class="stat-header">
              <h3>Low Stock Alerts</h3>
              <div class="icon-box rose"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg></div>
            </div>
            <p class="stat-number">0</p>
            <p class="stat-trend success">All stock levels healthy</p>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const activeTab = ref('dashboard');

const currentDate = ref(new Intl.DateTimeFormat('en-US', { 
  weekday: 'long', 
  year: 'numeric', 
  month: 'long', 
  day: 'numeric' 
}).format(new Date()));

onMounted(() => {
  const token = localStorage.getItem('access_token');
  if (!token) {
    router.push('/login');
  }
});

const handleLogout = () => {
  localStorage.removeItem('access_token');
  router.push('/login');
};
</script>
<style scoped>

.dashboard-layout {
  --primary: #283375;       
  --primary-hover: #1a2254; 
  --secondary: #4B6BB3;   
  --accent: #74A7E6;     
  --bg-main: #F4F6F9;       
  --sidebar-bg: #161c40;    
  --sidebar-hover: rgba(255, 255, 255, 0.08);
  --text-main: #111827;     
  --text-muted: #64748b;    
  --border-color: #E5E7EB;

  display: flex;
  height: 100vh;
  background-color: var(--bg-main);
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}


.sidebar {
  width: 270px;
  background-color: var(--sidebar-bg);
  color: white;
  display: flex;
  flex-direction: column;
  box-shadow: 4px 0 24px rgba(0,0,0,0.08);
  z-index: 10;
}
.logo-container {
  padding: 1.75rem 1.5rem;
  display: flex;
  align-items: center;
  gap: 12px;
  border-bottom: 1px solid rgba(255,255,255,0.06);
}
.logo-icon {
  background: linear-gradient(135deg, var(--accent) 0%, var(--secondary) 100%);
  padding: 8px;
  border-radius: 10px;
  display: flex;
  box-shadow: 0 4px 10px rgba(75, 107, 179, 0.3);
  color: white;
}

.logo-container h2 {
  font-size: 1.25rem;
  font-weight: 800; 
  margin: 0;
  letter-spacing: 0.5px;
  color: #FFFFFF; 
}

.menu {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 1.5rem 1rem;
  gap: 0.5rem;
}
.menu a {
  color: #9CA3AF;
  text-decoration: none;
  padding: 0.875rem 1rem;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 500;
  transition: all 0.2s ease;
  border-right: 3px solid transparent;
}
.menu-icon {
  opacity: 0.7;
  transition: opacity 0.2s ease;
}
.menu a:hover {
  background-color: var(--sidebar-hover);
  color: #F3F4F6;
}
.menu a.active {
  background-color: rgba(75, 107, 179, 0.15); 
  color: var(--accent); 
  border-right: 3px solid var(--accent);
  border-radius: 8px 0 0 8px; 
}
.menu a.active .menu-icon {
  opacity: 1;
  color: var(--accent);
}

.sidebar-footer {
  padding: 1.5rem 1rem;
  border-top: 1px solid rgba(255,255,255,0.06);
}
.logout-btn {
  width: 100%;
  padding: 0.875rem;
  background-color:rgba(255, 255, 255, 0.947);
  color: #F87171;
  border: 1px solid rgba(248, 113, 113, 0.2);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  cursor: pointer;
  font-size: 0.95rem;
  font-weight: 600;
  transition: all 0.2s ease;
}
.logout-btn:hover {
  background-color: rgba(0, 0, 0, 0.1);
  border-color: #ff0000;
}


.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}
.top-header {
  background-color: rgba(255, 255, 255, 0.85); 
  backdrop-filter: blur(12px); 
  padding: 1.25rem 2.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-color);
  position: sticky;
  top: 0;
  z-index: 5;
}
.header-left h1 {
  font-size: 1.4rem;
  font-weight: 700;
  color: var(--text-main);
  margin: 0 0 0.25rem 0;
}
.date-display {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin: 0;
}

.user-profile {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  padding: 6px 12px;
  border-radius: 8px;
  transition: background 0.2s;
}
.user-profile:hover {
  background-color: #e2e8f0;
}
.avatar {
  background-color: #EEF2FF;
  color: var(--primary);
  padding: 8px;
  border-radius: 50%;
  display: flex;
}
.user-info {
  display: flex;
  flex-direction: column;
}
.role {
  font-size: 0.7rem;
  text-transform: uppercase;
  color: var(--secondary);
  font-weight: 700;
  letter-spacing: 0.5px;
}
.name {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--text-main);
}


.content-area {
  padding: 2.5rem;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
}

/* Welcome Card */
.welcome-card {
  background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%); 
  color: white;
  padding: 2.5rem;
  border-radius: 16px;
  margin-bottom: 2.5rem;
  box-shadow: 0 10px 25px -5px rgba(40, 51, 117, 0.4);
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.welcome-text h2 {
  margin: 0 0 0.5rem 0;
  font-size: 1.75rem;
  font-weight: 700;
}
.welcome-text p {
  margin: 0;
  color: #E0E7FF;
  font-size: 1rem;
}
.action-btn {
  background-color: #FFFFFF;
  color: var(--primary);
  border: none;
  padding: 0.875rem 1.75rem;
  border-radius: 8px;
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
.action-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0,0,0,0.15);
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.5rem;
}
.stat-card {
  background: white;
  padding: 1.75rem;
  border-radius: 16px;
  border: 1px solid var(--border-color);
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03), 0 2px 4px -1px rgba(0,0,0,0.03);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}
.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 20px -5px rgba(0,0,0,0.08);
}
.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
}
.stat-header h3 {
  margin: 0;
  font-size: 0.95rem;
  color: var(--text-muted);
  font-weight: 600;
}
.icon-box {
  padding: 10px;
  border-radius: 10px;
  display: flex;
}

.icon-box.navy { background: #E8EBF5; color: var(--primary); }
.icon-box.ocean { background: #EDF1F8; color: var(--secondary); }
.icon-box.emerald { background: #ECFDF5; color: #10B981; }
.icon-box.rose { background: #FFF1F2; color: #E11D48; }

.stat-number {
  font-size: 2.5rem;
  font-weight: 800;
  color: var(--text-main);
  margin: 0 0 0.5rem 0;
  line-height: 1;
  letter-spacing: -1px;
}
.stat-trend {
  margin: 0;
  font-size: 0.875rem;
  font-weight: 500;
}
.stat-trend.neutral { color: #9CA3AF; }
.stat-trend.success { color: #059669; }
</style>