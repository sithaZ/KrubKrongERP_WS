<template>
  <section class="page-shell">
    <div class="page-header">
      <div>
        <h2>Employee Management</h2>
        <p>Manage employee records for attendance and payroll.</p>
      </div>

      <button @click="openAddModal" class="erp-btn">
        Add Employee
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
            <option value="">All</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>

        <div class="form-group">
          <label>Department</label>
          <select v-model="departmentFilter" class="erp-select">
            <option value="">All Departments</option>
            <option value="Sales">Sales</option>
            <option value="Operations">Operations</option>
            <option value="HR">HR</option>
            <option value="Finance">Finance</option>
            <option value="IT">IT</option>
            <option value="Admin">Admin</option>
            <option value="General">General</option>
          </select>
        </div>

        <div class="form-group">
          <button @click="fetchEmployees" class="erp-btn-secondary" type="button">
            Refresh
          </button>
        </div>
      </div>
    </div>

    <div class="erp-card table-card">
      <div class="table-scroll">
        <table class="erp-table employees-table">
          <thead>
            <tr>
              <th>Employee</th>
              <th>Code</th>
              <th>Position</th>
              <th>Department</th>
              <th>Salary</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>

          <tbody>
            <template v-if="isLoading">
              <tr
                v-for="row in skeletonRows"
                :key="`employee-skeleton-${row}`"
                class="skeleton-row"
                aria-hidden="true"
              >
                <td colspan="7">
                  <div class="table-skeleton-line"></div>
                </td>
              </tr>
            </template>

            <tr v-else-if="filteredEmployees.length === 0" class="state-row">
              <td colspan="7">No employees found.</td>
            </tr>

            <tr v-else v-for="employee in filteredEmployees" :key="employee._id">
              <td>
                <div class="user-cell">
                  <div class="user-avatar">
                    {{ employee.fullName?.charAt(0)?.toUpperCase() || 'E' }}
                  </div>
                  <span :title="employee.fullName || 'Unknown Employee'">
                    {{ employee.fullName || 'Unknown Employee' }}
                  </span>
                </div>
              </td>

              <td class="muted">{{ employee.employeeCode || '-' }}</td>
              <td :title="employee.position || 'Staff'">{{ employee.position || 'Staff' }}</td>
              <td :title="employee.department || 'General'">{{ employee.department || 'General' }}</td>
              <td class="salary-cell">
                {{ employee.salaryType || 'monthly' }} - ${{ Number(employee.baseSalary || 0).toFixed(2) }}
              </td>

              <td>
                <span class="status-pill" :class="employee.isActive ? 'active' : 'inactive'">
                  <span class="dot"></span>
                  {{ employee.isActive ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <td>
                <div class="actions-inline">
                  <button @click="openEditModal(employee)" class="erp-btn-soft" type="button">
                    Edit
                  </button>
                  <button @click="deactivateEmployee(employee._id)" class="erp-btn-danger" type="button">
                    Deactivate
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
            <h3>{{ isEditing ? 'Edit Employee' : 'Add New Employee' }}</h3>
            <p class="modal-subtitle">
              {{ isEditing ? 'Update employee information clearly.' : 'Create a new employee record for your HR system.' }}
            </p>
          </div>

          <button @click="closeModal" class="close-btn" type="button">✕</button>
        </div>

        <form @submit.prevent="saveEmployee" class="modal-form">
          <div class="form-row">
            <div class="form-group">
              <label>Full Name</label>
              <input v-model="formData.fullName" type="text" required placeholder="e.g. Sok Dara" class="erp-input" />
            </div>

            <div class="form-group">
              <label>Email</label>
              <input v-model="formData.email" type="email" required placeholder="e.g. employee@company.com" class="erp-input" />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Employee Code</label>
              <input v-model="formData.employeeCode" type="text" required placeholder="e.g. EMP001" class="erp-input" />
            </div>

            <div class="form-group">
              <label>Phone</label>
              <input v-model="formData.phone" type="text" placeholder="e.g. 095490904" class="erp-input" />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Position</label>
              <input v-model="formData.position" type="text" placeholder="e.g. Cashier" class="erp-input" />
            </div>

            <div class="form-group">
              <label>Department</label>
              <select v-model="formData.department" class="erp-select">
                <option value="">Select department</option>
                <option value="Sales">Sales</option>
                <option value="Operations">Operations</option>
                <option value="HR">HR</option>
                <option value="Finance">Finance</option>
                <option value="IT">IT</option>
                <option value="Admin">Admin</option>
                <option value="General">General</option>
              </select>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Salary Type</label>
              <select v-model="formData.salaryType" class="erp-select">
                <option value="daily">Daily</option>
                <option value="monthly">Monthly</option>
              </select>
            </div>

            <div class="form-group">
              <label>Base Salary</label>
              <input v-model.number="formData.baseSalary" type="number" min="0" required placeholder="e.g. 300" class="erp-input" />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Hire Date</label>
              <input v-model="formData.hireDate" type="date" class="erp-input" />
            </div>
          </div>

          <div class="form-group">
            <label>Status</label>
            <select v-model="formData.isActive" class="erp-select">
              <option :value="true">Active</option>
              <option :value="false">Inactive</option>
            </select>
          </div>

          <div class="helper-box">
            <strong>Tip:</strong> Saving a new employee now also creates an employee login account automatically.
          </div>

          <div class="modal-footer">
            <button type="button" @click="closeModal" class="erp-btn-secondary">Cancel</button>
            <button type="submit" class="erp-btn">Save Employee</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="accountCredentials" class="modal-overlay">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h3>Employee Account Ready</h3>
            <p class="modal-subtitle">
              Share these login details with the employee and ask them to change the password after first sign-in.
            </p>
          </div>

          <button @click="closeCredentialsModal" class="close-btn" type="button">✕</button>
        </div>

        <div class="modal-form">
          <div class="helper-box">
            <strong>Username:</strong> {{ accountCredentials.username }}<br />
            <strong>Temporary Password:</strong> {{ accountCredentials.temporaryPassword }}<br />
            <strong>Email:</strong> {{ accountCredentials.email }}
          </div>

          <div class="modal-footer">
            <button type="button" @click="copyCredentials" class="erp-btn-secondary">
              Copy Credentials
            </button>
            <button type="button" @click="closeCredentialsModal" class="erp-btn">
              Done
            </button>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

type AccountCredentials = {
  username: string
  temporaryPassword: string
  email: string
}

type Employee = {
  _id: string
  fullName: string
  email?: string
  employeeCode: string
  position?: string
  department?: string
  salaryType: 'daily' | 'monthly'
  baseSalary: number
  isActive: boolean
  phone?: string
  hireDate?: string
}

const API_BASE = 'http://localhost:3000/api'

const employees = ref<Employee[]>([])
const isLoading = ref(true)
const showModal = ref(false)
const isEditing = ref(false)
const currentEmployeeId = ref('')
const skeletonRows = Array.from({ length: 6 }, (_, index) => index)
const accountCredentials = ref<AccountCredentials | null>(null)

const searchTerm = ref('')
const statusFilter = ref('')
const departmentFilter = ref('')

const formData = ref({
  fullName: '',
  email: '',
  employeeCode: '',
  position: '',
  department: '',
  salaryType: 'monthly' as 'daily' | 'monthly',
  baseSalary: 0,
  isActive: true,
  phone: '',
  hireDate: '',
})

const getHeaders = () => {
  const token = localStorage.getItem('access_token')
  return {
    'Content-Type': 'application/json',
    Authorization: token ? `Bearer ${token}` : '',
  }
}

const normalizeDate = (value?: string | Date) => {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toISOString().split('T')[0]
}

const filteredEmployees = computed(() => {
  const search = searchTerm.value.toLowerCase().trim()

  return employees.value.filter((employee) => {
    const fullName = (employee.fullName || '').toLowerCase()
    const employeeCode = (employee.employeeCode || '').toLowerCase()
    const department = employee.department || 'General'

    const matchSearch =
      !search || fullName.includes(search) || employeeCode.includes(search)

    const matchStatus =
      !statusFilter.value ||
      (statusFilter.value === 'active' && employee.isActive) ||
      (statusFilter.value === 'inactive' && !employee.isActive)

    const matchDepartment =
      !departmentFilter.value || department === departmentFilter.value

    return matchSearch && matchStatus && matchDepartment
  })
})

const fetchEmployees = async () => {
  isLoading.value = true
  try {
    const res = await fetch(`${API_BASE}/employees`, { headers: getHeaders() })
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
  } finally {
    isLoading.value = false
  }
}

const openAddModal = () => {
  isEditing.value = false
  currentEmployeeId.value = ''
  accountCredentials.value = null
  formData.value = {
    fullName: '',
    email: '',
    employeeCode: '',
    position: '',
    department: '',
    salaryType: 'monthly',
    baseSalary: 0,
    isActive: true,
    phone: '',
    hireDate: '',
  }
  showModal.value = true
}

const openEditModal = (employee: Employee) => {
  isEditing.value = true
  currentEmployeeId.value = employee._id
  formData.value = {
    fullName: employee.fullName || '',
    email: employee.email || '',
    employeeCode: employee.employeeCode || '',
    position: employee.position || '',
    department: employee.department || '',
    salaryType: employee.salaryType || 'monthly',
    baseSalary: Number(employee.baseSalary || 0),
    isActive: employee.isActive ?? true,
    phone: employee.phone || '',
    hireDate: normalizeDate(employee.hireDate),
  }
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}

const closeCredentialsModal = () => {
  accountCredentials.value = null
}

const copyCredentials = async () => {
  if (!accountCredentials.value) return

  const text = [
    `Username: ${accountCredentials.value.username}`,
    `Temporary Password: ${accountCredentials.value.temporaryPassword}`,
    `Email: ${accountCredentials.value.email}`,
  ].join('\n')

  try {
    await navigator.clipboard.writeText(text)
  } catch (error) {
    console.error('Copy credentials error:', error)
  }
}

const saveEmployee = async () => {
  const payload = {
    fullName: formData.value.fullName,
    email: formData.value.email,
    employeeCode: formData.value.employeeCode,
    position: formData.value.position,
    department: formData.value.department,
    salaryType: formData.value.salaryType,
    baseSalary: Number(formData.value.baseSalary),
    isActive: formData.value.isActive,
    phone: formData.value.phone,
    hireDate: formData.value.hireDate || undefined,
  }

  const url = isEditing.value
    ? `${API_BASE}/employees/${currentEmployeeId.value}`
    : `${API_BASE}/employees`

  const method = isEditing.value ? 'PATCH' : 'POST'

  try {
    const response = await fetch(url, {
      method,
      headers: getHeaders(),
      body: JSON.stringify(payload),
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Save employee failed:', errorText)
      alert(errorText || 'Unable to save employee')
      return
    }

    const data = await response.json()

    closeModal()
    if (!isEditing.value && data?.credentials) {
      accountCredentials.value = data.credentials
    }
    await fetchEmployees()
  } catch (error) {
    console.error('Save employee error:', error)
    alert('Unable to save employee right now')
  }
}

const deactivateEmployee = async (id: string) => {
  if (!confirm('Deactivate this employee?')) return

  try {
    const response = await fetch(`${API_BASE}/employees/${id}/deactivate`, {
      method: 'PATCH',
      headers: getHeaders(),
    })

    if (!response.ok) {
      console.error('Deactivate employee failed:', await response.text())
      return
    }

    await fetchEmployees()
  } catch (error) {
    console.error('Deactivate employee error:', error)
  }
}

onMounted(fetchEmployees)
</script>
