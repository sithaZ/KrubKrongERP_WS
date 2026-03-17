<template>
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
</template>

<script setup lang="ts">
// You don't need any complex logic in here right now!
</script>

<style scoped>
/* These are your exact styles for the Dashboard Cards */
.content-area {
  padding: 2.5rem;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
  animation: fadeIn 0.3s ease; /* Adds a nice fade-in when you click the tab! */
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(5px); }
  to { opacity: 1; transform: translateY(0); }
}

.welcome-card {
  background: linear-gradient(135deg, #283375 0%, #4B6BB3 100%); 
  color: white;
  padding: 2.5rem;
  border-radius: 16px;
  margin-bottom: 2.5rem;
  box-shadow: 0 10px 25px -5px rgba(40, 51, 117, 0.4);
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.welcome-text h2 { margin: 0 0 0.5rem 0; font-size: 1.75rem; font-weight: 700; }
.welcome-text p { margin: 0; color: #E0E7FF; font-size: 1rem; }
.action-btn {
  background-color: #FFFFFF; color: #283375; border: none; padding: 0.875rem 1.75rem;
  border-radius: 8px; font-weight: 700; cursor: pointer; transition: transform 0.2s, box-shadow 0.2s;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
.action-btn:hover { transform: translateY(-2px); box-shadow: 0 6px 12px rgba(0,0,0,0.15); }

.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1.5rem; }
.stat-card {
  background: white; padding: 1.75rem; border-radius: 16px; border: 1px solid #E5E7EB;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03); transition: transform 0.2s ease, box-shadow 0.2s ease;
}
.stat-card:hover { transform: translateY(-4px); box-shadow: 0 12px 20px -5px rgba(0,0,0,0.08); }
.stat-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.25rem; }
.stat-header h3 { margin: 0; font-size: 0.95rem; color: #64748b; font-weight: 600; }
.icon-box { padding: 10px; border-radius: 10px; display: flex; }

.icon-box.navy { background: #E8EBF5; color: #283375; }
.icon-box.ocean { background: #EDF1F8; color: #4B6BB3; }
.icon-box.emerald { background: #ECFDF5; color: #10B981; }
.icon-box.rose { background: #FFF1F2; color: #E11D48; }

.stat-number { font-size: 2.5rem; font-weight: 800; color: #111827; margin: 0 0 0.5rem 0; line-height: 1; letter-spacing: -1px; }
.stat-trend { margin: 0; font-size: 0.875rem; font-weight: 500; }
.stat-trend.neutral { color: #9CA3AF; }
.stat-trend.success { color: #059669; }
</style>