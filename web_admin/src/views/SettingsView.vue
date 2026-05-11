<template>
  <section class="content-area">
    <div class="page-header">
      <h2>System Settings</h2>
      <p>Keep platform-wide rules and admin policies in one place.</p>
    </div>

    <div class="cards-grid">
      <div class="settings-card">
        <h3>Subscription Policy</h3>
        <p>Annual plan price remains $50 per shop and is managed from the Subscriptions page.</p>
      </div>

      <div class="settings-card">
        <h3>Role Boundaries</h3>
        <p>ADMIN manages shops and shop owners. Shop owners continue to handle employees, attendance, and payroll in Flutter/mobile_pos.</p>
      </div>

      <div class="settings-card">
        <h3>Compatibility</h3>
        <p>The UI uses the label Shop even when the backend still stores the relation as companyId.</p>
      </div>
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

.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1.5rem;
}

.settings-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 1.75rem;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.settings-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 20px -5px rgba(0,0,0,0.08);
}

.settings-card h3 { margin: 0 0 0.75rem 0; color: #111827; }
.settings-card p { margin: 0; color: #64748b; line-height: 1.6; }
</style>
