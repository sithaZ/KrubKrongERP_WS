<template>
  <section class="content-area subscriptions-page">
    <div class="page-header">
      <div>
        <h2>Subscriptions</h2>
        <p>Replace payroll with yearly shop subscriptions priced at $50 per year.</p>
      </div>

      <button class="erp-btn" type="button" @click="openModal()">Update Subscription</button>
    </div>

    <div class="erp-card pricing-card">
      <strong>Plan:</strong> KrubKrong Annual
      <span>$50 per shop / year</span>
    </div>

    <div class="erp-card toolbar-card">
      <div class="toolbar-grid">
        <div class="form-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            class="erp-input"
            placeholder="Shop, shop owner, contact, or city"
          />
        </div>

        <div class="form-group">
          <label>Status</label>
          <select v-model="statusFilter" class="erp-select">
            <option value="">All</option>
            <option v-for="status in subscriptionOptions" :key="status" :value="status">
              {{ status }}
            </option>
          </select>
        </div>

        <div class="form-group">
          <label>Payment</label>
          <select v-model="paymentFilter" class="erp-select">
            <option value="">All</option>
            <option value="Paid">Paid</option>
            <option value="Pending">Pending</option>
            <option value="Past Due">Past Due</option>
          </select>
        </div>

        <div class="form-group">
          <button class="erp-btn-secondary" type="button" @click="loadSubscriptions">Refresh</button>
        </div>
      </div>
    </div>

    <div v-if="errorMessage" class="erp-card error-banner">
      <strong>Unable to load subscriptions.</strong>
      <span>{{ errorMessage }}</span>
    </div>

    <div class="erp-card table-card">
      <div class="table-scroll">
        <table class="erp-table subscriptions-table">
          <thead>
            <tr>
              <th>Shop</th>
              <th>Shop Owner</th>
              <th>Plan</th>
              <th>Yearly Price</th>
              <th>Status</th>
              <th>Start</th>
              <th>End</th>
              <th>Next Renewal</th>
              <th>Payment</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="isLoading">
              <tr v-for="row in 6" :key="row" class="skeleton-row">
                <td colspan="10"><div class="table-skeleton-line"></div></td>
              </tr>
            </template>

            <tr v-else-if="filteredShops.length === 0" class="state-row">
              <td colspan="10">No subscriptions found.</td>
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
                <template v-else>
                  <strong>{{ shop.ownerName }}</strong><br />
                  <span class="muted">{{ shop.ownerEmail }}</span>
                </template>
              </td>
              <td>KrubKrong Annual</td>
              <td>${{ Number(shop.subscriptionPrice || 50).toFixed(2) }}</td>
              <td>
                <span class="status-pill" :class="statusClass(shop.subscriptionStatus)">
                  <span class="dot"></span>
                  {{ shop.subscriptionStatus }}
                </span>
              </td>
              <td>{{ formatDate(shop.subscriptionStartDate) }}</td>
              <td>{{ formatDate(shop.subscriptionEndDate) }}</td>
              <td>{{ formatDate(shop.nextRenewalDate) }}</td>
              <td>
                <span class="status-pill" :class="paymentClass(paymentLabel(shop))">
                  <span class="dot"></span>
                  {{ paymentLabel(shop) }}
                </span>
              </td>
              <td>
                <button class="erp-btn-soft" type="button" @click="openModal(shop)">Edit</button>
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
            <h3>{{ selectedShop ? 'Update Subscription' : 'Subscription Template' }}</h3>
            <p class="modal-subtitle">Manage yearly billing dates and access state for each shop.</p>
          </div>
          <button class="close-btn" type="button" @click="closeModal">X</button>
        </div>

        <form class="modal-form" @submit.prevent="saveSubscription">
          <div class="form-group">
            <label>Shop</label>
            <select v-model="subscriptionForm.shopId" class="erp-select" required>
              <option value="">Select shop</option>
              <option v-for="shop in shops" :key="shop._id" :value="shop._id">
                {{ shop.shopName }}
              </option>
            </select>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Subscription Status</label>
              <select v-model="subscriptionForm.subscriptionStatus" class="erp-select">
                <option v-for="status in subscriptionOptions" :key="status" :value="status">
                  {{ status }}
                </option>
              </select>
            </div>
            <div class="form-group">
              <label>Yearly Price</label>
              <input
                v-model.number="subscriptionForm.subscriptionPrice"
                class="erp-input"
                type="number"
                min="0"
                step="0.01"
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Subscription Start Date</label>
              <input v-model="subscriptionForm.subscriptionStartDate" class="erp-input" type="date" />
            </div>
            <div class="form-group">
              <label>Subscription End Date</label>
              <input v-model="subscriptionForm.subscriptionEndDate" class="erp-input" type="date" />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Next Renewal Date</label>
              <input v-model="subscriptionForm.nextRenewalDate" class="erp-input" type="date" />
            </div>
            <div class="form-group">
              <label>Shop Access</label>
              <select v-model="subscriptionForm.isActive" class="erp-select">
                <option :value="true">Enabled</option>
                <option :value="false">Blocked</option>
              </select>
            </div>
          </div>

          <p v-if="formError" class="form-error">{{ formError }}</p>

          <div class="modal-footer">
            <button class="erp-btn-secondary" type="button" @click="closeModal">Cancel</button>
            <button class="erp-btn" type="submit" :disabled="isSaving">
              {{ isSaving ? 'Saving...' : 'Save Subscription' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ApiError, apiFetch } from '../lib/adminApi'

type SubscriptionStatus = 'Trial' | 'Active' | 'Expired' | 'Suspended'
type PaymentStatus = 'Paid' | 'Pending' | 'Past Due'

type Shop = {
  _id: string
  shopName: string
  ownerName: string
  ownerEmail: string
  provinceOrCity?: string
  subscriptionStatus: SubscriptionStatus
  subscriptionPrice?: number
  subscriptionStartDate?: string
  subscriptionEndDate?: string
  nextRenewalDate?: string
  isActive: boolean
  managerId?: {
    name: string
    email: string
  } | null
}

const subscriptionOptions: SubscriptionStatus[] = ['Trial', 'Active', 'Expired', 'Suspended']

const shops = ref<Shop[]>([])
const isLoading = ref(true)
const isSaving = ref(false)
const errorMessage = ref('')
const formError = ref('')

const searchTerm = ref('')
const statusFilter = ref('')
const paymentFilter = ref('')

const showModal = ref(false)
const selectedShop = ref<Shop | null>(null)

const emptyForm = () => ({
  shopId: '',
  subscriptionStatus: 'Trial' as SubscriptionStatus,
  subscriptionPrice: 50,
  subscriptionStartDate: '',
  subscriptionEndDate: '',
  nextRenewalDate: '',
  isActive: true,
})

const subscriptionForm = ref(emptyForm())

const normalizeDate = (value?: string) => {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toISOString().split('T')[0]
}

const formatDate = (value?: string) => {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '-'
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

const paymentLabel = (shop: Shop): PaymentStatus => {
  if (shop.subscriptionStatus === 'Active') return 'Paid'
  if (shop.subscriptionStatus === 'Expired' || shop.subscriptionStatus === 'Suspended') {
    return 'Past Due'
  }
  return 'Pending'
}

const paymentClass = (status?: PaymentStatus) => {
  if (status === 'Paid') return 'active'
  if (status === 'Pending') return 'draft'
  return 'inactive'
}

const statusClass = (status: SubscriptionStatus) => {
  if (status === 'Active') return 'active'
  if (status === 'Trial') return 'draft'
  return 'inactive'
}

const filteredShops = computed(() => {
  const search = searchTerm.value.trim().toLowerCase()

  return shops.value.filter((shop) => {
    const paymentStatus = paymentLabel(shop)

    const matchesSearch =
      !search ||
      shop.shopName.toLowerCase().includes(search) ||
      shop.ownerName.toLowerCase().includes(search) ||
      shop.ownerEmail.toLowerCase().includes(search) ||
      (shop.managerId?.name || '').toLowerCase().includes(search) ||
      (shop.provinceOrCity || '').toLowerCase().includes(search)

    const matchesStatus = !statusFilter.value || shop.subscriptionStatus === statusFilter.value
    const matchesPayment = !paymentFilter.value || paymentStatus === paymentFilter.value

    return matchesSearch && matchesStatus && matchesPayment
  })
})

const loadSubscriptions = async () => {
  isLoading.value = true
  errorMessage.value = ''

  try {
    shops.value = await apiFetch<Shop[]>('/shops')
  } catch (error) {
    errorMessage.value = error instanceof ApiError ? error.message : 'Unable to load subscriptions.'
  } finally {
    isLoading.value = false
  }
}

const openModal = (shop?: Shop) => {
  selectedShop.value = shop || null
  formError.value = ''
  subscriptionForm.value = {
    shopId: shop?._id || '',
    subscriptionStatus: shop?.subscriptionStatus || 'Trial',
    subscriptionPrice: Number(shop?.subscriptionPrice || 50),
    subscriptionStartDate: normalizeDate(shop?.subscriptionStartDate),
    subscriptionEndDate: normalizeDate(shop?.subscriptionEndDate),
    nextRenewalDate: normalizeDate(shop?.nextRenewalDate),
    isActive: shop?.isActive ?? true,
  }
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}

const saveSubscription = async () => {
  if (!subscriptionForm.value.shopId) {
    formError.value = 'Please select a shop.'
    return
  }

  isSaving.value = true
  formError.value = ''

  try {
    await apiFetch(`/shops/${subscriptionForm.value.shopId}`, {
      method: 'PATCH',
      body: JSON.stringify({
        subscriptionStatus: subscriptionForm.value.subscriptionStatus,
        subscriptionPrice: Number(subscriptionForm.value.subscriptionPrice),
        subscriptionStartDate: subscriptionForm.value.subscriptionStartDate,
        subscriptionEndDate: subscriptionForm.value.subscriptionEndDate,
        nextRenewalDate: subscriptionForm.value.nextRenewalDate,
        isActive: subscriptionForm.value.isActive,
      }),
    })

    closeModal()
    await loadSubscriptions()
  } catch (error) {
    formError.value = error instanceof ApiError ? error.message : 'Unable to save subscription.'
  } finally {
    isSaving.value = false
  }
}

onMounted(loadSubscriptions)
</script>

<style scoped>
.subscriptions-page {
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

.subscriptions-page :deep(.page-header h2) {
  font-size: 1.75rem;
}

.subscriptions-page :deep(.erp-card) {
  border-radius: 16px;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03);
}

.pricing-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #eff6ff;
  border-color: #bfdbfe;
  color: #1e3a8a;
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

@media (max-width: 768px) {
  .subscriptions-page {
    padding: 1.25rem;
  }

  .pricing-card {
    flex-direction: column;
    align-items: start;
    gap: 0.35rem;
  }
}
</style>
