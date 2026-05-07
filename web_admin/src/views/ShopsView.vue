<template>
  <section class="page-shell">
    <div class="page-header">
      <div>
        <h2>Shops / Businesses</h2>
        <p>Build the ERP flow from admin to shop manager, employee, attendance, and payroll.</p>
      </div>

      <button class="erp-btn" type="button" @click="openCreateShopModal">
        Create Shop
      </button>
    </div>

    <div class="erp-card toolbar-card">
      <div class="toolbar-grid">
        <div class="form-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            placeholder="Search by shop, owner, or business type"
            class="erp-input"
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
          <label>Manager</label>
          <select v-model="managerFilter" class="erp-select">
            <option value="">All Managers</option>
            <option value="assigned">Assigned</option>
            <option value="unassigned">Unassigned</option>
          </select>
        </div>

        <div class="form-group">
          <button class="erp-btn-secondary" type="button" @click="refreshData">
            Refresh
          </button>
        </div>
      </div>
    </div>

    <div class="erp-card table-card">
      <div class="table-scroll">
        <table class="erp-table shops-table">
          <thead>
            <tr>
              <th>Shop</th>
              <th>Owner</th>
              <th>Manager</th>
              <th>Phone</th>
              <th>Business Type</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="isLoading">
              <tr v-for="row in skeletonRows" :key="`shop-skeleton-${row}`" class="skeleton-row">
                <td colspan="7">
                  <div class="table-skeleton-line"></div>
                </td>
              </tr>
            </template>

            <tr v-else-if="filteredShops.length === 0" class="state-row">
              <td colspan="7">No shops found.</td>
            </tr>

            <tr v-else v-for="shop in filteredShops" :key="shop._id">
              <td>
                <div class="user-cell">
                  <div class="user-avatar">
                    {{ (shop.shopName || 'S').charAt(0).toUpperCase() }}
                  </div>
                  <span :title="shop.shopName">{{ shop.shopName }}</span>
                </div>
              </td>
              <td class="left-cell">
                <strong>{{ shop.ownerName }}</strong><br />
                <span class="muted">{{ shop.ownerEmail }}</span>
              </td>
              <td class="left-cell">
                <template v-if="shop.managerId && typeof shop.managerId === 'object'">
                  <strong>{{ shop.managerId.name || 'Assigned Manager' }}</strong><br />
                  <span class="muted">{{ shop.managerId.email || '-' }}</span>
                </template>
                <span v-else class="muted">Not assigned</span>
              </td>
              <td>{{ shop.phone || '-' }}</td>
              <td>{{ shop.businessType || '-' }}</td>
              <td>
                <span class="status-pill" :class="shop.status === 'active' ? 'active' : 'inactive'">
                  <span class="dot"></span>
                  {{ shop.status }}
                </span>
              </td>
              <td>
                <div class="actions-inline">
                  <button class="erp-btn-soft" type="button" @click="openEditShopModal(shop)">
                    Edit
                  </button>
                  <button class="erp-btn-secondary" type="button" @click="openAssignManagerModal(shop)">
                    Assign Manager
                  </button>
                  <button class="erp-btn" type="button" @click="openCreateManagerModal(shop)">
                    Create Manager
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="showShopModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>{{ isEditingShop ? 'Edit Shop' : 'Create Shop' }}</h3>
            <p class="modal-subtitle">Set up the business first, then attach the right manager account.</p>
          </div>
          <button class="close-btn" type="button" @click="closeShopModal">×</button>
        </div>

        <form class="modal-form" @submit.prevent="saveShop">
          <div class="form-row">
            <div class="form-group">
              <label>Shop Name</label>
              <input v-model="shopForm.shopName" type="text" class="erp-input" required />
            </div>
            <div class="form-group">
              <label>Business Type</label>
              <input v-model="shopForm.businessType" type="text" class="erp-input" placeholder="Retail, Restaurant, Salon..." />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Owner Name</label>
              <input v-model="shopForm.ownerName" type="text" class="erp-input" required />
            </div>
            <div class="form-group">
              <label>Owner Email</label>
              <input v-model="shopForm.ownerEmail" type="email" class="erp-input" required />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Phone</label>
              <input v-model="shopForm.phone" type="text" class="erp-input" />
            </div>
            <div class="form-group">
              <label>Status</label>
              <select v-model="shopForm.status" class="erp-select">
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label>Address</label>
            <textarea v-model="shopForm.address" rows="3" class="erp-textarea"></textarea>
          </div>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="closeShopModal">Cancel</button>
            <button class="erp-btn" type="submit">{{ isEditingShop ? 'Save Changes' : 'Create Shop' }}</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showAssignManagerModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>Assign Manager</h3>
            <p class="modal-subtitle">Attach an existing manager to {{ selectedShop?.shopName || 'this shop' }}.</p>
          </div>
          <button class="close-btn" type="button" @click="closeAssignManagerModal">×</button>
        </div>

        <form class="modal-form" @submit.prevent="assignManager">
          <div class="form-group">
            <label>Manager</label>
            <select v-model="assignManagerForm.managerId" class="erp-select" required>
              <option value="">Select manager</option>
              <option v-for="manager in managers" :key="manager.id" :value="manager.id">
                {{ manager.name }} ({{ manager.email }})
              </option>
            </select>
          </div>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="closeAssignManagerModal">Cancel</button>
            <button class="erp-btn" type="submit">Assign Manager</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showCreateManagerModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>Create Shop Manager</h3>
            <p class="modal-subtitle">Create a manager account directly under {{ selectedShop?.shopName || 'this shop' }}.</p>
          </div>
          <button class="close-btn" type="button" @click="closeCreateManagerModal">×</button>
        </div>

        <form class="modal-form" @submit.prevent="createManager">
          <div class="form-row">
            <div class="form-group">
              <label>Name</label>
              <input v-model="managerForm.name" type="text" class="erp-input" required />
            </div>
            <div class="form-group">
              <label>Email</label>
              <input v-model="managerForm.email" type="email" class="erp-input" required />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Phone</label>
              <input v-model="managerForm.phone" type="text" class="erp-input" />
            </div>
            <div class="form-group">
              <label>Password</label>
              <input v-model="managerForm.password" type="password" class="erp-input" required minlength="6" />
            </div>
          </div>

          <div class="helper-box">
            <strong>Note:</strong> The new manager will automatically belong to this shop and only see employees, attendance, and payroll inside it.
          </div>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="closeCreateManagerModal">Cancel</button>
            <button class="erp-btn" type="submit">Create Manager</button>
          </div>
        </form>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

type Manager = {
  id: string
  name: string
  email: string
  phone?: string | null
}

type ShopManagerRef =
  | string
  | {
      _id?: string
      name?: string
      email?: string
      phone?: string
    }
  | null

type Shop = {
  _id: string
  shopName: string
  ownerName: string
  ownerEmail: string
  phone?: string
  address?: string
  businessType?: string
  status: 'active' | 'inactive'
  managerId?: ShopManagerRef
}

const API_BASE = 'http://localhost:3000/api'

const shops = ref<Shop[]>([])
const managers = ref<Manager[]>([])
const isLoading = ref(true)
const searchTerm = ref('')
const statusFilter = ref('')
const managerFilter = ref('')
const skeletonRows = Array.from({ length: 6 }, (_, index) => index)

const showShopModal = ref(false)
const isEditingShop = ref(false)
const currentShopId = ref('')

const showAssignManagerModal = ref(false)
const showCreateManagerModal = ref(false)
const selectedShop = ref<Shop | null>(null)

const shopForm = ref({
  shopName: '',
  ownerName: '',
  ownerEmail: '',
  phone: '',
  address: '',
  businessType: '',
  status: 'active' as 'active' | 'inactive',
})

const assignManagerForm = ref({
  managerId: '',
})

const managerForm = ref({
  name: '',
  email: '',
  phone: '',
  password: '',
})

const getHeaders = () => {
  const token = localStorage.getItem('token')
  return {
    'Content-Type': 'application/json',
    Authorization: token ? `Bearer ${token}` : '',
  }
}

const filteredShops = computed(() => {
  const search = searchTerm.value.toLowerCase().trim()

  return shops.value.filter((shop) => {
    const matchSearch =
      !search ||
      shop.shopName.toLowerCase().includes(search) ||
      shop.ownerName.toLowerCase().includes(search) ||
      (shop.businessType || '').toLowerCase().includes(search)

    const matchStatus = !statusFilter.value || shop.status === statusFilter.value

    const hasManager = !!shop.managerId
    const matchManager =
      !managerFilter.value ||
      (managerFilter.value === 'assigned' && hasManager) ||
      (managerFilter.value === 'unassigned' && !hasManager)

    return matchSearch && matchStatus && matchManager
  })
})

const fetchShops = async () => {
  isLoading.value = true
  try {
    const response = await fetch(`${API_BASE}/shops`, {
      headers: getHeaders(),
    })

    if (!response.ok) {
      console.error('Failed to fetch shops:', await response.text())
      shops.value = []
      return
    }

    const data = await response.json()
    shops.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Fetch shops error:', error)
    shops.value = []
  } finally {
    isLoading.value = false
  }
}

const fetchManagers = async () => {
  try {
    const response = await fetch(`${API_BASE}/users?role=MANAGER`, {
      headers: getHeaders(),
    })

    if (!response.ok) {
      console.error('Failed to fetch managers:', await response.text())
      managers.value = []
      return
    }

    const data = await response.json()
    managers.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Fetch managers error:', error)
    managers.value = []
  }
}

const refreshData = async () => {
  await Promise.all([fetchShops(), fetchManagers()])
}

const resetShopForm = () => {
  shopForm.value = {
    shopName: '',
    ownerName: '',
    ownerEmail: '',
    phone: '',
    address: '',
    businessType: '',
    status: 'active',
  }
}

const openCreateShopModal = () => {
  isEditingShop.value = false
  currentShopId.value = ''
  resetShopForm()
  showShopModal.value = true
}

const openEditShopModal = (shop: Shop) => {
  isEditingShop.value = true
  currentShopId.value = shop._id
  shopForm.value = {
    shopName: shop.shopName || '',
    ownerName: shop.ownerName || '',
    ownerEmail: shop.ownerEmail || '',
    phone: shop.phone || '',
    address: shop.address || '',
    businessType: shop.businessType || '',
    status: shop.status || 'active',
  }
  showShopModal.value = true
}

const closeShopModal = () => {
  showShopModal.value = false
}

const saveShop = async () => {
  const isEdit = isEditingShop.value
  const url = isEdit ? `${API_BASE}/shops/${currentShopId.value}` : `${API_BASE}/shops`
  const method = isEdit ? 'PATCH' : 'POST'

  try {
    const response = await fetch(url, {
      method,
      headers: getHeaders(),
      body: JSON.stringify(shopForm.value),
    })

    if (!response.ok) {
      alert(await response.text())
      return
    }

    closeShopModal()
    await refreshData()
  } catch (error) {
    console.error('Save shop error:', error)
  }
}

const openAssignManagerModal = (shop: Shop) => {
  selectedShop.value = shop
  assignManagerForm.value.managerId =
    typeof shop.managerId === 'object' && shop.managerId?._id ? shop.managerId._id : ''
  showAssignManagerModal.value = true
}

const closeAssignManagerModal = () => {
  showAssignManagerModal.value = false
}

const assignManager = async () => {
  if (!selectedShop.value) return

  try {
    const response = await fetch(`${API_BASE}/shops/${selectedShop.value._id}/assign-manager`, {
      method: 'PATCH',
      headers: getHeaders(),
      body: JSON.stringify(assignManagerForm.value),
    })

    if (!response.ok) {
      alert(await response.text())
      return
    }

    closeAssignManagerModal()
    await refreshData()
  } catch (error) {
    console.error('Assign manager error:', error)
  }
}

const openCreateManagerModal = (shop: Shop) => {
  selectedShop.value = shop
  managerForm.value = {
    name: '',
    email: '',
    phone: '',
    password: '',
  }
  showCreateManagerModal.value = true
}

const closeCreateManagerModal = () => {
  showCreateManagerModal.value = false
}

const createManager = async () => {
  if (!selectedShop.value) return

  try {
    const response = await fetch(`${API_BASE}/shops/${selectedShop.value._id}/manager`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify(managerForm.value),
    })

    if (!response.ok) {
      alert(await response.text())
      return
    }

    closeCreateManagerModal()
    await refreshData()
  } catch (error) {
    console.error('Create manager error:', error)
  }
}

onMounted(refreshData)
</script>
