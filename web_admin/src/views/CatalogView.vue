<template>
  <section class="content-area">
    <div class="page-header">
      <h2>Product Catalog</h2>
      <p>Manage platform catalog visibility for shops without exposing employee operations here.</p>
    </div>

    <div class="placeholder-box">
      <div class="icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></svg>
      </div>
      <h3>Catalog Module</h3>
      <p>This section stays available for platform-level product and category governance.</p>
    </div>
  </section>
</template>

<style scoped>
.content-area {
  padding: 2.5rem;
  max-width: 1400px;
  margin: 0 auto;
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

.page-header { margin-bottom: 2rem; }
.page-header h2 { font-size: 1.75rem; color: #111827; margin: 0 0 0.5rem 0; }
.page-header p { color: #64748b; margin: 0; }

.placeholder-box {
  background: white;
  border: 1px dashed #cbd5e1;
  border-radius: 12px;
  padding: 4rem;
  text-align: center;
  color: #64748b;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.04);
}

.placeholder-box .icon {
  margin-bottom: 1rem;
  color: #94a3b8;
  display: flex;
  justify-content: center;
}

.placeholder-box h3 { color: #111827; margin: 0 0 0.5rem 0; }
</style>
