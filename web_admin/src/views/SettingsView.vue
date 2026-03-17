<template>
  <section class="content-area">
    <div class="page-header">
      <h2>System Settings</h2>
      <p>Configure taxes, store details, and technical preferences.</p>
    </div>
    
    <div class="placeholder-box">
      <div class="icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>
      </div>
      <h3>Settings Module Coming Soon</h3>
      <p>This is where your configuration forms will be displayed.</p>
    </div>
  </section>
</template>

<script setup lang="ts">

</script>

<style scoped>
.content-area { padding: 2.5rem; max-width: 1400px; margin: 0 auto; animation: fadeIn 0.3s ease; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

.page-header { margin-bottom: 2rem; }
.page-header h2 { font-size: 1.75rem; color: #111827; margin: 0 0 0.5rem 0; }
.page-header p { color: #64748b; margin: 0; }

.placeholder-box {
  background: white; border: 1px dashed #cbd5e1; border-radius: 12px;
  padding: 4rem; text-align: center; color: #64748b;
}
.placeholder-box .icon { 
  margin-bottom: 1rem; 
  color: #94a3b8;
  display: flex;
  justify-content: center;
}
.placeholder-box h3 { color: #111827; margin: 0 0 0.5rem 0; }
</style>