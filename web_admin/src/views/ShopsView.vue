<template>
  <section class="content-area shops-page">
    <div class="page-header">
      <div>
        <h2>Shops</h2>
        <p>Create shops, update business details, enable or disable access, and assign a shop owner.</p>
      </div>

      <button class="erp-btn" type="button" @click="openCreateModal">Add Shop</button>
    </div>

    <div class="erp-card toolbar-card">
      <div class="toolbar-grid">
        <div class="form-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            class="erp-input"
            placeholder="Shop name, owner, business type, or city"
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
          <label>Subscription</label>
          <select v-model="subscriptionFilter" class="erp-select">
            <option value="">All</option>
            <option v-for="item in subscriptionOptions" :key="item" :value="item">
              {{ item }}
            </option>
          </select>
        </div>

        <div class="form-group">
          <button class="erp-btn-secondary" type="button" @click="loadPage">Refresh</button>
        </div>
      </div>
    </div>

    <div v-if="errorMessage" class="erp-card error-banner">
      <strong>Unable to load shops.</strong>
      <span>{{ errorMessage }}</span>
    </div>

    <div class="erp-card table-card">
      <div class="table-scroll">
        <table class="erp-table shops-table">
          <thead>
            <tr>
              <th>Shop</th>
              <th>Shop Owner</th>
              <th>Business</th>
              <th>Status</th>
              <th>Subscription</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="isLoading">
              <tr v-for="row in 6" :key="row" class="skeleton-row">
                <td colspan="6"><div class="table-skeleton-line"></div></td>
              </tr>
            </template>

            <tr v-else-if="filteredShops.length === 0" class="state-row">
              <td colspan="6">No shops match the current filters.</td>
            </tr>

            <tr v-for="shop in filteredShops" :key="shop._id">
              <td class="left-cell">
                <strong>{{ shop.shopName }}</strong><br />
                <span class="muted">{{ shop.provinceOrCity || 'No city provided' }}</span>
              </td>
              <td class="left-cell">
                <template v-if="shop.managerId">
                  <strong>{{ shop.managerId.name }}</strong><br />
                  <span class="muted">{{ shop.managerId.email }}</span>
                </template>
                <template v-else-if="shop.ownerName || shop.ownerEmail">
                  <strong>{{ shop.ownerName || 'Unassigned' }}</strong><br />
                  <span class="muted">{{ shop.ownerEmail || 'No email provided' }}</span>
                </template>
                <span v-else class="muted">Unassigned</span>
              </td>
              <td class="left-cell">
                <strong>{{ shop.businessType || 'General' }}</strong><br />
                <span class="muted">{{ shop.whatTheySell || shop.description || 'No summary yet' }}</span>
              </td>
              <td>
                <span class="status-pill" :class="shop.status === 'active' ? 'active' : 'inactive'">
                  <span class="dot"></span>
                  {{ shop.status === 'active' ? 'Enabled' : 'Disabled' }}
                </span>
              </td>
              <td>
                <span class="status-pill" :class="subscriptionPillClass(shop.subscriptionStatus)">
                  <span class="dot"></span>
                  {{ shop.subscriptionStatus }}
                </span>
              </td>
              <td>
                <div class="actions-inline">
                  <button class="erp-btn-soft" type="button" @click="openEditModal(shop)">Edit</button>
                  <button class="erp-btn-secondary" type="button" @click="openAssignModal(shop)">
                    Assign Shop Owner
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="showModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>{{ isEditing ? 'Edit Shop' : 'Create Shop' }}</h3>
            <p class="modal-subtitle">The backend may still store this as companyId, but the UI labels it as Shop.</p>
          </div>
          <button class="close-btn" type="button" @click="closeModal">X</button>
        </div>

        <form class="modal-form" @submit.prevent="saveShop">
          <div class="form-row">
            <div class="form-group">
              <label>Shop Name</label>
              <input v-model="shopForm.shopName" class="erp-input" type="text" required />
            </div>
            <div class="form-group">
              <label>Business Type</label>
              <input v-model="shopForm.businessType" class="erp-input" type="text" />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Owner Name</label>
              <input v-model="shopForm.ownerName" class="erp-input" type="text" required />
            </div>
            <div class="form-group">
              <label>Owner Email</label>
              <input v-model="shopForm.ownerEmail" class="erp-input" type="email" required />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Phone</label>
              <input v-model="shopForm.phone" class="erp-input" type="text" />
            </div>
            <div class="form-group">
              <label>Province or City</label>
              <input v-model="shopForm.provinceOrCity" class="erp-input" type="text" />
            </div>
          </div>

          <div class="form-group">
            <label>Address</label>
            <textarea v-model="shopForm.address" class="erp-textarea" rows="3"></textarea>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Description</label>
              <textarea v-model="shopForm.description" class="erp-textarea" rows="3"></textarea>
            </div>
            <div class="form-group">
              <label>What They Sell</label>
              <textarea v-model="shopForm.whatTheySell" class="erp-textarea" rows="3"></textarea>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Status</label>
              <select v-model="shopForm.status" class="erp-select">
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>
            <div class="form-group">
              <label>Subscription Status</label>
              <select v-model="shopForm.subscriptionStatus" class="erp-select">
                <option v-for="item in subscriptionOptions" :key="item" :value="item">
                  {{ item }}
                </option>
              </select>
            </div>
          </div>

          <p v-if="formError" class="form-error">{{ formError }}</p>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="closeModal">Cancel</button>
            <button class="erp-btn" type="submit" :disabled="isSaving">
              {{ isSaving ? 'Saving...' : isEditing ? 'Save Shop' : 'Create Shop' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showAssignModal && selectedShop" class="modal-overlay">
      <div class="modal-content assign-modal">
        <div class="modal-header">
          <div>
            <h3>Assign Shop Owner</h3>
            <p class="modal-subtitle">Attach the shop owner account to {{ selectedShop.shopName }}.</p>
          </div>
          <button class="close-btn" type="button" @click="closeAssignModal">X</button>
        </div>

        <div class="modal-form">
          <div class="form-group">
            <label>Shop Owner</label>
            <select v-model="assignManagerId" class="erp-select">
              <option value="">Choose a shop owner</option>
              <option v-for="manager in managers" :key="manager.id" :value="manager.id">
                {{ manager.name }} - {{ manager.email }}
              </option>
            </select>
          </div>

          <p v-if="assignError" class="form-error">{{ assignError }}</p>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="closeAssignModal">Cancel</button>
            <button class="erp-btn" type="button" :disabled="isAssigning" @click="assignManager">
              {{ isAssigning ? 'Assigning...' : 'Assign Shop Owner' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ApiError, apiFetch } from '../lib/adminApi'

type SubscriptionStatus = 'Trial' | 'Active' | 'Expired' | 'Suspended'

type ManagerOption = {
  id: string
  name: string
  email: string
}

type Shop = {
  _id: string
  shopName: string
  businessType?: string
  description?: string
  whatTheySell?: string
  address?: string
  provinceOrCity?: string
  phone?: string
  ownerName: string
  ownerEmail: string
  status: 'active' | 'inactive'
  subscriptionStatus: SubscriptionStatus
  managerId?: {
    id?: string
    _id?: string
    name: string
    email: string
  } | null
}

const subscriptionOptions: SubscriptionStatus[] = ['Trial', 'Active', 'Expired', 'Suspended']

const shops = ref<Shop[]>([])
const managers = ref<ManagerOption[]>([])
const isLoading = ref(true)
const isSaving = ref(false)
const isAssigning = ref(false)
const errorMessage = ref('')
const formError = ref('')
const assignError = ref('')

const searchTerm = ref('')
const statusFilter = ref('')
const subscriptionFilter = ref('')

const showModal = ref(false)
const isEditing = ref(false)
const currentShopId = ref('')

const showAssignModal = ref(false)
const selectedShop = ref<Shop | null>(null)
const assignManagerId = ref('')

const emptyShopForm = () => ({
  shopName: '',
  businessType: '',
  description: '',
  whatTheySell: '',
  address: '',
  provinceOrCity: '',
  phone: '',
  ownerName: '',
  ownerEmail: '',
  status: 'active' as const,
  subscriptionStatus: 'Trial' as SubscriptionStatus,
})

const shopForm = ref(emptyShopForm())

const filteredShops = computed(() => {
  const search = searchTerm.value.trim().toLowerCase()

  return shops.value.filter((shop) => {
    const matchesSearch =
      !search ||
      shop.shopName.toLowerCase().includes(search) ||
      shop.ownerName.toLowerCase().includes(search) ||
      (shop.businessType || '').toLowerCase().includes(search) ||
      (shop.provinceOrCity || '').toLowerCase().includes(search)

    const matchesStatus = !statusFilter.value || shop.status === statusFilter.value
    const matchesSubscription =
      !subscriptionFilter.value || shop.subscriptionStatus === subscriptionFilter.value

    return matchesSearch && matchesStatus && matchesSubscription
  })
})

const subscriptionPillClass = (status: SubscriptionStatus) => {
  if (status === 'Active') return 'active'
  if (status === 'Trial') return 'draft'
  return 'inactive'
}

const loadPage = async () => {
  isLoading.value = true
  errorMessage.value = ''

  try {
    const [shopData, managerData] = await Promise.all([
      apiFetch<Shop[]>('/shops'),
      apiFetch<ManagerOption[]>('/users?role=MANAGER'),
    ])

    shops.value = shopData
    managers.value = managerData
  } catch (error) {
    errorMessage.value = error instanceof ApiError ? error.message : 'Unable to load shops.'
  } finally {
    isLoading.value = false
  }
}

const openCreateModal = () => {
  isEditing.value = false
  currentShopId.value = ''
  shopForm.value = emptyShopForm()
  formError.value = ''
  showModal.value = true
}

const openEditModal = (shop: Shop) => {
  isEditing.value = true
  currentShopId.value = shop._id
  formError.value = ''
  shopForm.value = {
    shopName: shop.shopName,
    businessType: shop.businessType || '',
    description: shop.description || '',
    whatTheySell: shop.whatTheySell || '',
    address: shop.address || '',
    provinceOrCity: shop.provinceOrCity || '',
    phone: shop.phone || '',
    ownerName: shop.ownerName,
    ownerEmail: shop.ownerEmail,
    status: shop.status,
    subscriptionStatus: shop.subscriptionStatus,
  }
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}

const saveShop = async () => {
  isSaving.value = true
  formError.value = ''

  try {
    if (isEditing.value) {
      await apiFetch(`/shops/${currentShopId.value}`, {
        method: 'PATCH',
        body: JSON.stringify(shopForm.value),
      })
    } else {
      await apiFetch('/shops', {
        method: 'POST',
        body: JSON.stringify(shopForm.value),
      })
    }

    closeModal()
    await loadPage()
  } catch (error) {
    formError.value = error instanceof ApiError ? error.message : 'Unable to save shop.'
  } finally {
    isSaving.value = false
  }
}

const openAssignModal = (shop: Shop) => {
  selectedShop.value = shop
  assignManagerId.value = shop.managerId?.id || shop.managerId?._id || ''
  assignError.value = ''
  showAssignModal.value = true
}

const closeAssignModal = () => {
  showAssignModal.value = false
  selectedShop.value = null
}

const assignManager = async () => {
  if (!selectedShop.value || !assignManagerId.value) {
    assignError.value = 'Please select a shop owner first.'
    return
  }

  isAssigning.value = true
  assignError.value = ''

  try {
    await apiFetch(`/shops/${selectedShop.value._id}/assign-manager`, {
      method: 'PATCH',
      body: JSON.stringify({ managerId: assignManagerId.value }),
    })

    closeAssignModal()
    await loadPage()
  } catch (error) {
    assignError.value = error instanceof ApiError ? error.message : 'Unable to assign shop owner.'
  } finally {
    isAssigning.value = false
  }
}

onMounted(loadPage)
</script>

<style scoped>
.shops-page {
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

.shops-page :deep(.page-header h2) {
  font-size: 1.75rem;
}

.shops-page :deep(.erp-card) {
  border-radius: 16px;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03);
}

.error-banner,
.form-error {
  color: #991b1b;
}

.error-banner {
  background: #fff5f5;
  border-color: #fecaca;
}

.form-error {
  margin: 0;
  font-size: 0.92rem;
}

.assign-modal {
  width: min(560px, 100%);
}

@media (max-width: 768px) {
  .shops-page {
    padding: 1.25rem;
  }
}
</style>
