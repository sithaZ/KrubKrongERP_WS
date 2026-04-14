<template>
  <section class="page-shell">
    <div class="page-header">
      <div>
        <h2>Payroll Management</h2>
        <p>Generate and finalize employee payroll records.</p>
      </div>

      <button @click="openGenerateModal" class="erp-btn">
        Generate Payroll
      </button>
    </div>

    <div class="erp-card toolbar-card">
      <div class="toolbar-grid">
        <div class="form-group">
          <label>Search</label>
          <input
            v-model="searchTerm"
            type="text"
            placeholder="Search by employee name or code"
            class="erp-input"
          />
        </div>

        <div class="form-group">
          <label>Status</label>
          <select v-model="statusFilter" class="erp-select">
            <option value="">All Statuses</option>
            <option value="draft">Draft</option>
            <option value="finalized">Finalized</option>
          </select>
        </div>

        <div class="form-group">
          <label>Month</label>
          <input v-model="monthFilter" type="month" class="erp-input" />
        </div>

        <div class="form-group">
          <button @click="fetchPayrolls" class="erp-btn-secondary" type="button">
            Refresh
          </button>
        </div>
      </div>
    </div>

    <div class="erp-card table-card">
      <div class="table-scroll">
        <table class="erp-table payroll-table">
          <thead>
            <tr>
              <th>Employee</th>
              <th>Code</th>
              <th>Month</th>
              <th>Present</th>
              <th>Late</th>
              <th>Absent</th>
              <th>Gross</th>
              <th>Deduction</th>
              <th>Net</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr v-if="isLoading" class="state-row">
              <td colspan="11">Loading payroll records...</td>
            </tr>

            <tr v-else-if="filteredPayrolls.length === 0" class="state-row">
              <td colspan="11">No payroll records found.</td>
            </tr>

            <tr v-else v-for="payroll in filteredPayrolls" :key="payroll._id">
              <td>
                <div class="user-cell">
                  <div class="user-avatar">
                    {{ (getEmployeeName(payroll) || 'U').charAt(0).toUpperCase() }}
                  </div>
                  <span :title="getEmployeeName(payroll)">
                    {{ getEmployeeName(payroll) }}
                  </span>
                </div>
              </td>

              <td class="muted">{{ getEmployeeCode(payroll) }}</td>
              <td>{{ payroll.month || '-' }}</td>
              <td>{{ payroll.presentDays ?? 0 }}</td>
              <td>{{ payroll.lateDays ?? 0 }}</td>
              <td>{{ payroll.absentDays ?? 0 }}</td>
              <td class="salary-cell">${{ Number(payroll.grossSalary || 0).toFixed(2) }}</td>
              <td class="salary-cell">${{ Number(payroll.deduction || 0).toFixed(2) }}</td>
              <td class="salary-cell">${{ Number(payroll.netSalary || 0).toFixed(2) }}</td>

              <td>
                <span class="status-pill" :class="payroll.status || 'draft'">
                  <span class="dot"></span>
                  {{ formatStatus(payroll.status || 'draft') }}
                </span>
              </td>

              <td>
                <div class="actions-inline">
                  <button
                    v-if="payroll.status !== 'finalized'"
                    @click="finalizePayroll(payroll._id)"
                    class="erp-btn-soft"
                    type="button"
                  >
                    Finalize
                  </button>
                  <span v-else class="muted">Done</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="showGenerateModal" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>Generate Payroll</h3>
            <p class="modal-subtitle">
              Select an employee and month to generate payroll.
            </p>
          </div>

          <button @click="closeGenerateModal" class="close-btn" type="button">✕</button>
        </div>

        <form @submit.prevent="generatePayroll" class="modal-form">
          <div class="form-group">
            <label>Employee</label>
            <select v-model="generateForm.employeeId" class="erp-select" required>
              <option value="">Select employee</option>
              <option v-for="employee in employees" :key="employee._id" :value="employee._id">
                {{ employee.fullName }} ({{ employee.employeeCode }})
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>Month</label>
            <input v-model="generateForm.month" type="month" class="erp-input" required />
          </div>

          <div class="helper-box">
            <strong>Tip:</strong> Generate payroll after attendance records are complete for the selected month.
          </div>

          <div class="modal-footer">
            <button type="button" @click="closeGenerateModal" class="erp-btn-secondary">
              Cancel
            </button>
            <button type="submit" class="erp-btn">
              Generate
            </button>
          </div>
        </form>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

type EmployeeRef = {
  _id?: string
  fullName?: string
  employeeCode?: string
}

type PayrollRecord = {
  _id: string
  employeeId: EmployeeRef | string | null
  month: string
  presentDays: number
  absentDays: number
  lateDays: number
  halfDays: number
  grossSalary: number
  deduction: number
  netSalary: number
  status: 'draft' | 'finalized'
}

type Employee = {
  _id: string
  fullName: string
  employeeCode: string
}

const API_BASE = 'http://localhost:3000/api'

const payrolls = ref<PayrollRecord[]>([])
const employees = ref<Employee[]>([])
const isLoading = ref(true)
const showGenerateModal = ref(false)

const searchTerm = ref('')
const statusFilter = ref('')
const monthFilter = ref('')

const generateForm = ref({
  employeeId: '',
  month: '',
})

const getHeaders = () => {
  const token = localStorage.getItem('access_token')
  return {
    'Content-Type': 'application/json',
    Authorization: token ? `Bearer ${token}` : '',
  }
}

const getEmployeeName = (payroll: PayrollRecord) => {
  if (!payroll) return 'Unknown Employee'
  if (typeof payroll.employeeId === 'object' && payroll.employeeId !== null) {
    return payroll.employeeId.fullName || 'Unknown Employee'
  }
  return 'Unknown Employee'
}

const getEmployeeCode = (payroll: PayrollRecord) => {
  if (!payroll) return '-'
  if (typeof payroll.employeeId === 'object' && payroll.employeeId !== null) {
    return payroll.employeeId.employeeCode || '-'
  }
  return '-'
}

const formatStatus = (status: string) =>
  status.charAt(0).toUpperCase() + status.slice(1)

const filteredPayrolls = computed(() => {
  return payrolls.value.filter((payroll) => {
    const name = getEmployeeName(payroll).toLowerCase()
    const code = getEmployeeCode(payroll).toLowerCase()
    const search = searchTerm.value.toLowerCase().trim()

    const matchSearch = !search || name.includes(search) || code.includes(search)
    const matchStatus = !statusFilter.value || payroll.status === statusFilter.value
    const matchMonth = !monthFilter.value || payroll.month === monthFilter.value

    return matchSearch && matchStatus && matchMonth
  })
})

const fetchPayrolls = async () => {
  isLoading.value = true
  try {
    const res = await fetch(`${API_BASE}/payroll`, {
      headers: getHeaders(),
    })

    if (!res.ok) {
      console.error('Failed to fetch payrolls:', await res.text())
      payrolls.value = []
      return
    }

    const data = await res.json()
    payrolls.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Fetch payrolls error:', error)
    payrolls.value = []
  } finally {
    isLoading.value = false
  }
}

const fetchEmployees = async () => {
  try {
    const res = await fetch(`${API_BASE}/employees`, {
      headers: getHeaders(),
    })

    if (!res.ok) {
      console.error('Failed to fetch employees:', await res.text())
      employees.value = []
      return
    }

    const data = await res.json()
    employees.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Fetch employees error:', error)
    employees.value = []
  }
}

const openGenerateModal = () => {
  generateForm.value = {
    employeeId: '',
    month: '',
  }
  showGenerateModal.value = true
}

const closeGenerateModal = () => {
  showGenerateModal.value = false
}

const generatePayroll = async () => {
  try {
    const response = await fetch(`${API_BASE}/payroll/generate`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify(generateForm.value),
    })

    if (!response.ok) {
      console.error('Generate payroll failed:', await response.text())
      return
    }

    closeGenerateModal()
    await fetchPayrolls()
  } catch (error) {
    console.error('Generate payroll error:', error)
  }
}

const finalizePayroll = async (id: string) => {
  if (!confirm('Finalize this payroll?')) return

  try {
    const response = await fetch(`${API_BASE}/payroll/${id}/finalize`, {
      method: 'PATCH',
      headers: getHeaders(),
    })

    if (!response.ok) {
      console.error('Finalize payroll failed:', await response.text())
      return
    }

    await fetchPayrolls()
  } catch (error) {
    console.error('Finalize payroll error:', error)
  }
}

onMounted(async () => {
  await Promise.all([fetchPayrolls(), fetchEmployees()])
})
</script>