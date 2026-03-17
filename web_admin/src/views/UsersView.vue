<template>
  <section class="content-area">
    
    <div class="page-header">
      <div class="header-left">
        <h2>User Management</h2>
        <p>Manage system administrators and staff access for KrubKrong ERP.</p>
      </div>
      <button @click="openAddModal" class="action-btn">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
        Add Employee
      </button>
    </div>
    
    <div class="table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Username</th>
            <th>Email</th>
            <th>System Role</th>
            <th>Account Status</th>
            <th class="text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="isLoading">
            <td colspan="5" class="text-center empty-state">Loading users...</td>
          </tr>
          <tr v-else-if="users.length === 0">
            <td colspan="5" class="text-center empty-state">No users found.</td>
          </tr>
          
          <tr v-else v-for="user in users" :key="user.id">
            <td class="font-medium username-cell">
              <div class="user-avatar-small">{{ user.username.charAt(0).toUpperCase() }}</div>
              {{ user.username }}
            </td>
            <td class="text-muted">{{ user.email || 'N/A' }}</td>
            <td>
              <span class="role-badge" :class="user.role === 'ADMIN' ? 'admin' : 'staff'">
                {{ user.role }}
              </span>
            </td>
            <td>
              <span class="status-badge" :class="user.isActive ? 'active' : 'inactive'">
                <span class="status-dot"></span>
                {{ user.isActive ? 'Active' : 'Deactivated' }}
              </span>
            </td>
            <td class="actions-cell">
              <div class="actions-wrapper">
                <button @click="openEditModal(user)" class="btn-icon edit">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                  Edit
                </button>
                <button @click="deleteUser(user.id)" class="btn-icon delete">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
                  Delete
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ isEditing ? 'Edit Employee Details' : 'Add New Employee' }}</h3>
          <button @click="closeModal" class="close-btn">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
          </button>
        </div>
        
        <form @submit.prevent="saveUser" class="modal-form">
          <div class="form-row">
            <div class="form-group">
              <label>Username</label>
              <input type="text" v-model="formData.username" required placeholder="e.g. cashier_01" class="chunky-input" />
            </div>
            
            <div class="form-group">
              <label>Email <span class="hint">(Optional)</span></label>
              <input type="email" v-model="formData.email" placeholder="staff@example.com" class="chunky-input" />
            </div>
          </div>
          
          <div class="form-group">
            <label>Password <span class="hint">{{ isEditing ? '(Leave blank to keep current)' : '' }}</span></label>
            <input type="password" v-model="formData.password" :required="!isEditing" placeholder="••••••••" class="chunky-input" />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>System Role</label>
              <div class="select-wrapper">
                <select v-model="formData.role" class="chunky-input">
                  <option value="STAFF">Staff (Mobile POS Only)</option>
                  <option value="ADMIN">Admin (Full Access)</option>
                </select>
              </div>
            </div>
            
            <div class="form-group">
              <label>Account Status</label>
              <div class="select-wrapper">
                <select v-model="formData.isActive" class="chunky-input">
                  <option :value="true">Active (Can Log In)</option>
                  <option :value="false">Deactivated (Locked Out)</option>
                </select>
              </div>
            </div>
          </div>

          <div class="modal-footer">
            <button type="button" @click="closeModal" class="btn-cancel">Cancel</button>
            <button type="submit" class="btn-save">Save Employee</button>
          </div>
        </form>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';

const users = ref<any[]>([]);
const isLoading = ref(true);

const showModal = ref(false);
const isEditing = ref(false);
const currentUserId = ref('');
// 👇 ADDED EMAIL TO STATE 👇
const formData = ref({ username: '', email: '', password: '', role: 'STAFF', isActive: true });

const getHeaders = () => ({
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${localStorage.getItem('access_token')}`
});

const fetchUsers = async () => {
  isLoading.value = true;
  try {
    const res = await fetch('http://localhost:3000/api/users', { headers: getHeaders() });
    if (res.ok) users.value = await res.json();
  } catch (e) { console.error(e); }
  isLoading.value = false;
};

const openAddModal = () => {
  isEditing.value = false;
  // 👇 ADDED EMAIL RESET 👇
  formData.value = { username: '', email: '', password: '', role: 'STAFF', isActive: true };
  showModal.value = true;
};

const openEditModal = (user: any) => {
  isEditing.value = true;
  currentUserId.value = user.id;
  
  const isUserActive = user.isActive === true || user.isActive === 'true' || user.isActive === null || user.isActive === undefined;

  formData.value = {
    username: user.username,
    email: user.email || '', 
    password: '', 
    role: user.role || 'STAFF',
    isActive: isUserActive
  };
  showModal.value = true;
};

const closeModal = () => showModal.value = false;

const saveUser = async () => {
  const url = isEditing.value ? `http://localhost:3000/api/users/${currentUserId.value}` : `http://localhost:3000/api/users`;
  const method = isEditing.value ? 'PUT' : 'POST';

  const payload: any = {
    username: formData.value.username,
    email: formData.value.email,
    role: formData.value.role,
    isActive: formData.value.isActive === true || formData.value.isActive === 'true'
  };

  if (formData.value.password && formData.value.password.trim() !== '') {
    payload.password = formData.value.password;
  }

  try {
    const response = await fetch(url, { 
      method, 
      headers: getHeaders(), 
      body: JSON.stringify(payload) 
    });
    
    if (response.ok) {
      closeModal();
      fetchUsers(); 
    } else {
      alert('Failed to save user. Check backend console.');
    }
  } catch (e) { 
    alert('Error saving user'); 
  }
};

const deleteUser = async (id: string) => {
  if (confirm('Are you sure you want to permanently delete this user?')) {
    try {
      await fetch(`http://localhost:3000/api/users/${id}`, { method: 'DELETE', headers: getHeaders() });
      fetchUsers();
    } catch (e) { console.error(e); }
  }
};

onMounted(fetchUsers);
</script>

<style scoped>
/* Keeping all your exact same gorgeous CSS styles from before! */
.content-area { padding: 3.5rem 3rem; max-width: 1500px; margin: 0 auto; animation: fadeIn 0.3s ease; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
.page-header { display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 3rem; }
.page-header h2 { font-size: 2.2rem; color: #111827; margin: 0 0 0.75rem 0; letter-spacing: -0.5px; }
.page-header p { color: #64748b; font-size: 1.1rem; margin: 0; }
.action-btn { background: #283375; color: white; border: none; padding: 1rem 2rem; border-radius: 12px; font-size: 1.05rem; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 10px; transition: all 0.2s ease; box-shadow: 0 4px 12px rgba(40, 51, 117, 0.2); }
.action-btn:hover { transform: translateY(-3px); box-shadow: 0 8px 20px rgba(40, 51, 117, 0.3); background: #1a2254; }
.table-card { background: white; border: 1px solid #E2E8F0; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.05); }
.data-table { width: 100%; border-collapse: collapse; text-align: left; }
.data-table th { background: #F8FAFC; padding: 1.5rem 2.5rem; font-size: 0.95rem; font-weight: 700; color: #475569; text-transform: uppercase; letter-spacing: 0.08em; border-bottom: 2px solid #E2E8F0; }
.text-right { text-align: right; }
.data-table td { padding: 1.5rem 2.5rem; border-bottom: 1px solid #F1F5F9; color: #334155; font-size: 1.05rem; vertical-align: middle; }
.text-muted { color: #64748b; font-size: 0.95rem; }
.data-table tbody tr { transition: background-color 0.2s ease; }
.data-table tbody tr:hover { background-color: #F8FAFC; }
.data-table tr:last-child td { border-bottom: none; }
.username-cell { display: flex; align-items: center; gap: 1rem; }
.user-avatar-small { width: 40px; height: 40px; border-radius: 10px; background: #EEF2FF; color: #4B6BB3; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 1.1rem; }
.font-medium { font-weight: 600; color: #0f172a; }
.empty-state { padding: 4rem !important; color: #94a3b8; font-size: 1.1rem; }
.role-badge { padding: 0.5rem 1rem; border-radius: 8px; font-size: 0.85rem; font-weight: 700; letter-spacing: 0.5px; }
.role-badge.admin { background: #EEF2FF; color: #4B6BB3; border: 1px solid #E0E7FF; }
.role-badge.staff { background: #F1F5F9; color: #475569; border: 1px solid #E2E8F0; }
.status-badge { display: inline-flex; align-items: center; gap: 8px; padding: 0.5rem 1rem; border-radius: 8px; font-size: 0.85rem; font-weight: 600; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.status-badge.active { background: #ECFDF5; color: #065F46; border: 1px solid #D1FAE5; }
.status-badge.active .status-dot { background: #10B981; }
.status-badge.inactive { background: #FEF2F2; color: #991B1B; border: 1px solid #FEE2E2; }
.status-badge.inactive .status-dot { background: #EF4444; }
.actions-cell { text-align: right; }
.actions-wrapper { display: inline-flex; gap: 0.75rem; justify-content: flex-end; }
.btn-icon { display: flex; align-items: center; gap: 8px; background: white; border: 1px solid #E2E8F0; padding: 0.6rem 1.25rem; border-radius: 8px; font-weight: 600; font-size: 0.9rem; cursor: pointer; transition: all 0.2s; }
.btn-icon.edit { color: #4B6BB3; }
.btn-icon.edit:hover { background: #EEF2FF; border-color: #C7D2FE; }
.btn-icon.delete { color: #EF4444; }
.btn-icon.delete:hover { background: #FEF2F2; border-color: #FECACA; }
.modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(15, 23, 42, 0.75); backdrop-filter: blur(6px); display: flex; justify-content: center; align-items: center; z-index: 100; }
.modal-content { background: white; width: 100%; max-width: 650px; border-radius: 20px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); animation: modalPop 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes modalPop { 0% { opacity: 0; transform: scale(0.95) translateY(20px); } 100% { opacity: 1; transform: scale(1) translateY(0); } }
.modal-header { padding: 2rem 2.5rem; border-bottom: 1px solid #F1F5F9; display: flex; justify-content: space-between; align-items: center; }
.modal-header h3 { margin: 0; font-size: 1.5rem; font-weight: 700; color: #0f172a; }
.close-btn { background: none; border: none; color: #94a3b8; cursor: pointer; transition: color 0.2s; padding: 0; }
.close-btn:hover { color: #0f172a; transform: scale(1.1); }
.modal-form { padding: 2.5rem; }
.form-group { margin-bottom: 1.75rem; display: flex; flex-direction: column; gap: 0.75rem; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; } 
label { font-size: 0.95rem; font-weight: 600; color: #334155; }
.hint { font-weight: 400; color: #94a3b8; font-size: 0.85rem; }
.chunky-input { padding: 1.15rem 1.5rem; border: 2px solid #E2E8F0; border-radius: 12px; font-size: 1.05rem; color: #0f172a; outline: none; transition: all 0.2s; background: #F8FAFC; width: 100%; box-sizing: border-box; }
.chunky-input:focus { border-color: #4B6BB3; background: white; box-shadow: 0 0 0 4px rgba(75, 107, 179, 0.1); }
.select-wrapper { position: relative; }
.select-wrapper::after { content: '▼'; font-size: 0.8rem; color: #64748b; position: absolute; right: 1.5rem; top: 50%; transform: translateY(-50%); pointer-events: none; }
select.chunky-input { appearance: none; cursor: pointer; }
.modal-footer { display: flex; justify-content: flex-end; gap: 1.25rem; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid #F1F5F9; }
.btn-cancel { background: white; border: 2px solid #E2E8F0; padding: 1rem 2rem; border-radius: 12px; font-size: 1.05rem; font-weight: 600; color: #475569; cursor: pointer; transition: all 0.2s; }
.btn-cancel:hover { background: #F1F5F9; border-color: #CBD5E1; color: #0f172a; }
.btn-save { background: #283375; border: none; padding: 1rem 2.5rem; border-radius: 12px; font-size: 1.05rem; font-weight: 700; color: white; cursor: pointer; transition: all 0.2s; box-shadow: 0 4px 12px rgba(40, 51, 117, 0.2); }
.btn-save:hover { background: #1a2254; transform: translateY(-2px); box-shadow: 0 6px 15px rgba(40, 51, 117, 0.3); }
</style>