<template>
  <section class="content-area managers-page">
    <div class="page-header">
      <div>
        <h2>Shop Owners</h2>
        <p>Create, edit, activate, deactivate, reset passwords, and reassign shop owners between shops.</p>
      </div>

      <button class="erp-btn" type="button" @click="openCreateModal">Create Shop Owner</button>
    </div>

    <div class="erp-card toolbar-card">
      <div class="toolbar-grid">
        <div class="form-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            class="erp-input"
            placeholder="Name, email, username, or shop"
          />
        </div>

        <div class="form-group">
          <label>Status</label>
          <select v-model="statusFilter" class="erp-select">
            <option value="">All</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>

        <div class="form-group">
          <label>Shop</label>
          <select v-model="shopFilter" class="erp-select">
            <option value="">All shops</option>
            <option v-for="shop in shops" :key="shop._id" :value="shop._id">
              {{ shop.shopName }}
            </option>
          </select>
        </div>

        <div class="form-group">
          <button class="erp-btn-secondary" type="button" @click="loadPage">Refresh</button>
        </div>
      </div>
    </div>

    <div v-if="errorMessage" class="erp-card error-banner">
      <strong>Unable to load shop owners.</strong>
      <span>{{ errorMessage }}</span>
    </div>

    <div class="erp-card table-card">
      <div class="table-scroll">
        <table class="erp-table managers-table">
          <thead>
            <tr>
              <th>Shop Owner</th>
              <th>Username</th>
              <th>Shop</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="isLoading">
              <tr v-for="row in 6" :key="row" class="skeleton-row">
                <td colspan="5"><div class="table-skeleton-line"></div></td>
              </tr>
            </template>

            <tr v-else-if="filteredManagers.length === 0" class="state-row">
              <td colspan="5">No shop owners found.</td>
            </tr>

            <tr v-for="manager in filteredManagers" :key="manager.id">
              <td class="left-cell">
                <strong>{{ manager.name }}</strong><br />
                <span class="muted">{{ manager.email }}{{ manager.phone ? ` | ${manager.phone}` : '' }}</span>
              </td>
              <td>{{ manager.username }}</td>
              <td>{{ shopNameFor(manager.companyId) }}</td>
              <td>
                <span class="status-pill" :class="manager.isActive ? 'active' : 'inactive'">
                  <span class="dot"></span>
                  {{ manager.isActive ? 'Active' : 'Inactive' }}
                </span>
              </td>
              <td>
                <div class="actions-inline">
                  <button class="action-chip edit" type="button" @click="openEditModal(manager)">
                    Edit
                  </button>
                  <button class="action-chip assign" type="button" @click="openAssignModal(manager)">
                    Reassign Shop
                  </button>
                  <button class="action-chip reset" type="button" @click="resetPassword(manager)">
                    Reset Password
                  </button>
                  <button
                    class="action-chip"
                    :class="manager.isActive ? 'deactivate' : 'activate'"
                    type="button"
                    @click="toggleManager(manager)"
                  >
                    {{ manager.isActive ? 'Deactivate' : 'Activate' }}
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="showFormModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>{{ isEditing ? 'Edit Shop Owner' : 'Create Shop Owner' }}</h3>
            <p class="modal-subtitle">Shop owners use the MANAGER role internally so the same account can log in to Flutter for shop operations.</p>
          </div>
          <button class="close-btn" type="button" @click="closeFormModal">X</button>
        </div>

        <form class="modal-form" @submit.prevent="saveManager">
          <div class="form-row">
            <div class="form-group">
              <label>Name</label>
              <input v-model="managerForm.name" class="erp-input" type="text" required />
            </div>
            <div class="form-group">
              <label>Email</label>
              <input v-model="managerForm.email" class="erp-input" type="email" required />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Phone</label>
              <input v-model="managerForm.phone" class="erp-input" type="text" />
            </div>
            <div class="form-group">
              <label>Username</label>
              <input v-model="managerForm.username" class="erp-input" type="text" required />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Shop</label>
              <select v-model="managerForm.shopId" class="erp-select" required>
                <option value="">Select shop</option>
                <option v-for="shop in shops" :key="shop._id" :value="shop._id">
                  {{ shop.shopName }}
                </option>
              </select>
            </div>
            <div class="form-group">
              <label>Status</label>
              <select v-model="managerForm.isActive" class="erp-select">
                <option :value="true">Active</option>
                <option :value="false">Inactive</option>
              </select>
            </div>
          </div>

          <div v-if="!isEditing" class="form-group">
            <label>Temporary Password</label>
            <input
              v-model="managerForm.temporaryPassword"
              class="erp-input"
              type="text"
              minlength="6"
              required
            />
          </div>

          <div class="helper-box">
            Role is fixed to <strong>MANAGER</strong> internally. Passwords are only shown after create or reset.
          </div>

          <p v-if="formError" class="form-error">{{ formError }}</p>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="closeFormModal">Cancel</button>
            <button class="erp-btn" type="submit" :disabled="isSaving">
              {{ isSaving ? 'Saving...' : isEditing ? 'Save Shop Owner' : 'Create Shop Owner' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showAssignShopModal && selectedManager" class="modal-overlay">
      <div class="modal-content assign-modal">
        <div class="modal-header">
          <div>
            <h3>Assign Shop</h3>
            <p class="modal-subtitle">Reassign {{ selectedManager.name }} as the shop owner for a different shop.</p>
          </div>
          <button class="close-btn" type="button" @click="closeAssignModal">X</button>
        </div>

        <div class="modal-form">
          <div class="form-group">
            <label>Shop</label>
            <select v-model="assignShopId" class="erp-select">
              <option value="">Select shop</option>
              <option v-for="shop in shops" :key="shop._id" :value="shop._id">
                {{ shop.shopName }}
              </option>
            </select>
          </div>

          <p v-if="assignError" class="form-error">{{ assignError }}</p>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="closeAssignModal">Cancel</button>
            <button class="erp-btn" type="button" :disabled="isAssigning" @click="assignShop">
              {{ isAssigning ? 'Saving...' : 'Assign Shop' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="credentialsModal" class="modal-overlay">
      <div class="modal-content assign-modal">
        <div class="modal-header">
          <div>
            <h3>Temporary Credentials</h3>
            <p class="modal-subtitle">Share these one-time credentials with the shop owner securely.</p>
          </div>
          <button class="close-btn" type="button" @click="credentialsModal = null">X</button>
        </div>

        <div class="modal-form">
          <div class="helper-box credentials-box">
            <div><strong>Username:</strong> {{ credentialsModal.username }}</div>
            <div><strong>Email:</strong> {{ credentialsModal.email }}</div>
            <div><strong>Temporary Password:</strong> {{ credentialsModal.temporaryPassword }}</div>
          </div>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="copyCredentials">Copy</button>
            <button class="erp-btn" type="button" @click="credentialsModal = null">Done</button>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ApiError, apiFetch } from '../lib/adminApi'

type Shop = {
  _id: string
  shopName: string
}

type Manager = {
  id: string
  name: string
  email: string
  phone?: string | null
  username: string
  companyId?: string | { _id?: string; shopName?: string } | null
  isActive: boolean
}

type Credentials = {
  username: string
  email: string
  temporaryPassword: string
}

const shops = ref<Shop[]>([])
const managers = ref<Manager[]>([])
const isLoading = ref(true)
const isSaving = ref(false)
const isAssigning = ref(false)
const errorMessage = ref('')
const formError = ref('')
const assignError = ref('')

const searchTerm = ref('')
const statusFilter = ref('')
const shopFilter = ref('')

const showFormModal = ref(false)
const isEditing = ref(false)
const currentManagerId = ref('')

const showAssignShopModal = ref(false)
const selectedManager = ref<Manager | null>(null)
const assignShopId = ref('')

const credentialsModal = ref<Credentials | null>(null)

const emptyManagerForm = () => ({
  name: '',
  email: '',
  phone: '',
  username: '',
  shopId: '',
  isActive: true,
  temporaryPassword: '',
})

const managerForm = ref(emptyManagerForm())

const normalizeShopId = (value?: string | { _id?: string } | null) =>
  typeof value === 'string' ? value : value?._id || ''

const shopNameFor = (value?: string | { _id?: string; shopName?: string } | null) => {
  if (!value) return 'Unassigned'
  if (typeof value === 'object') return value.shopName || 'Unassigned'
  return shops.value.find((shop) => shop._id === value)?.shopName || 'Unassigned'
}

const filteredManagers = computed(() => {
  const search = searchTerm.value.trim().toLowerCase()

  return managers.value.filter((manager) => {
    const matchesSearch =
      !search ||
      manager.name.toLowerCase().includes(search) ||
      manager.email.toLowerCase().includes(search) ||
      manager.username.toLowerCase().includes(search) ||
      shopNameFor(manager.companyId).toLowerCase().includes(search)

    const matchesStatus =
      !statusFilter.value ||
      (statusFilter.value === 'active' && manager.isActive) ||
      (statusFilter.value === 'inactive' && !manager.isActive)

    const matchesShop =
      !shopFilter.value || normalizeShopId(manager.companyId) === shopFilter.value

    return matchesSearch && matchesStatus && matchesShop
  })
})

const loadPage = async () => {
  isLoading.value = true
  errorMessage.value = ''

  try {
    const [shopData, managerData] = await Promise.all([
      apiFetch<Shop[]>('/shops'),
      apiFetch<Manager[]>('/users?role=MANAGER'),
    ])

    shops.value = shopData
    managers.value = managerData
  } catch (error) {
    errorMessage.value = error instanceof ApiError ? error.message : 'Unable to load shop owners.'
  } finally {
    isLoading.value = false
  }
}

const openCreateModal = () => {
  isEditing.value = false
  currentManagerId.value = ''
  managerForm.value = emptyManagerForm()
  formError.value = ''
  showFormModal.value = true
}

const openEditModal = (manager: Manager) => {
  isEditing.value = true
  currentManagerId.value = manager.id
  formError.value = ''
  managerForm.value = {
    name: manager.name,
    email: manager.email,
    phone: manager.phone || '',
    username: manager.username,
    shopId: normalizeShopId(manager.companyId),
    isActive: manager.isActive,
    temporaryPassword: '',
  }
  showFormModal.value = true
}

const closeFormModal = () => {
  showFormModal.value = false
}

const saveManager = async () => {
  if (!managerForm.value.shopId) {
    formError.value = 'Please select a shop.'
    return
  }

  isSaving.value = true
  formError.value = ''

  try {
    if (isEditing.value) {
      await apiFetch(`/users/${currentManagerId.value}`, {
        method: 'PUT',
        body: JSON.stringify({
          name: managerForm.value.name,
          email: managerForm.value.email,
          phone: managerForm.value.phone,
          username: managerForm.value.username,
          isActive: managerForm.value.isActive,
        }),
      })

      await apiFetch(`/users/${currentManagerId.value}/assign-shop`, {
        method: 'PUT',
        body: JSON.stringify({ shopId: managerForm.value.shopId }),
      })
    } else {
      const result = await apiFetch<{ credentials?: Credentials }>(
        `/shops/${managerForm.value.shopId}/manager`,
        {
          method: 'POST',
          body: JSON.stringify({
            name: managerForm.value.name,
            email: managerForm.value.email,
            phone: managerForm.value.phone,
            username: managerForm.value.username,
            temporaryPassword: managerForm.value.temporaryPassword,
          }),
        },
      )

      credentialsModal.value = result.credentials || null
    }

    closeFormModal()
    await loadPage()
  } catch (error) {
    formError.value = error instanceof ApiError ? error.message : 'Unable to save shop owner.'
  } finally {
    isSaving.value = false
  }
}

const openAssignModal = (manager: Manager) => {
  selectedManager.value = manager
  assignShopId.value = normalizeShopId(manager.companyId)
  assignError.value = ''
  showAssignShopModal.value = true
}

const closeAssignModal = () => {
  showAssignShopModal.value = false
  selectedManager.value = null
}

const assignShop = async () => {
  if (!selectedManager.value || !assignShopId.value) {
    assignError.value = 'Please select a shop.'
    return
  }

  isAssigning.value = true
  assignError.value = ''

  try {
    await apiFetch(`/users/${selectedManager.value.id}/assign-shop`, {
      method: 'PUT',
      body: JSON.stringify({ shopId: assignShopId.value }),
    })

    closeAssignModal()
    await loadPage()
  } catch (error) {
    assignError.value = error instanceof ApiError ? error.message : 'Unable to assign shop.'
  } finally {
    isAssigning.value = false
  }
}

const toggleManager = async (manager: Manager) => {
  try {
    await apiFetch(`/users/${manager.id}`, {
      method: 'PUT',
      body: JSON.stringify({ isActive: !manager.isActive }),
    })
    await loadPage()
  } catch (error) {
    errorMessage.value = error instanceof ApiError ? error.message : 'Unable to update shop owner status.'
  }
}

const resetPassword = async (manager: Manager) => {
  try {
    credentialsModal.value = await apiFetch<Credentials>(
      `/users/${manager.id}/reset-manager-password`,
      {
        method: 'POST',
      },
    )
  } catch (error) {
    errorMessage.value = error instanceof ApiError ? error.message : 'Unable to reset password.'
  }
}

const copyCredentials = async () => {
  if (!credentialsModal.value) return

  const payload = [
    `Username: ${credentialsModal.value.username}`,
    `Email: ${credentialsModal.value.email}`,
    `Temporary Password: ${credentialsModal.value.temporaryPassword}`,
  ].join('\n')

  await navigator.clipboard.writeText(payload)
}

onMounted(loadPage)
</script>

<style scoped>
.managers-page {
  padding: 2.5rem;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
  display: grid;
  gap: 1.25rem;
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(5px); }
  to { opacity: 1; transform: translateY(0); }
}

.managers-page :deep(.page-header h2) {
  font-size: 1.75rem;
}

.managers-page :deep(.erp-card) {
  border-radius: 16px;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03);
}

.error-banner {
  background: #fff5f5;
  border-color: #fecaca;
  color: #991b1b;
}

.form-error {
  margin: 0;
  color: #991b1b;
  font-size: 0.92rem;
}

.assign-modal {
  width: min(560px, 100%);
}

.credentials-box {
  display: grid;
  gap: 0.45rem;
}

.actions-inline {
  display: flex;
  flex-wrap: wrap;
  gap: 0.55rem;
}

.action-chip {
  border: 0;
  border-radius: 999px;
  padding: 0.55rem 0.85rem;
  font-size: 0.84rem;
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.18s ease, box-shadow 0.18s ease;
}

.action-chip:hover {
  transform: translateY(-1px);
}

.action-chip.edit {
  background: #dbeafe;
  color: #1d4ed8;
}

.action-chip.assign {
  background: #ede9fe;
  color: #6d28d9;
}

.action-chip.reset {
  background: #fef3c7;
  color: #b45309;
}

.action-chip.activate {
  background: #d1fae5;
  color: #047857;
}

.action-chip.deactivate {
  background: #fee2e2;
  color: #b91c1c;
}

@media (max-width: 768px) {
  .managers-page {
    padding: 1.25rem;
  }
}
</style>
