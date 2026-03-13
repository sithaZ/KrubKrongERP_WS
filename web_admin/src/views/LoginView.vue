<template>
  <div class="login-container">
    
    <div class="animated-bg-text">
      {{ animatedText }}<span class="blinking-cursor">|</span>
    </div>

    <div class="login-box" :style="boxStyle">
      
      <div 
        class="brand-header" 
        @mousedown="startDrag" 
        :class="{ 'is-grabbing': isDragging }"
      >
        <h2>KrubKrong ERP Login</h2>
        <p class="subtitle">Secure access to your business dashboard</p>
      </div>

      <form @submit.prevent="handleLogin" class="auth-form">
        <div class="input-group">
          <label>Username</label>
          <div class="input-wrapper">
            <input 
              type="text" 
              v-model="username" 
              required 
              placeholder="Enter your username" 
            />
          </div>
        </div>

        <div class="input-group">
          <label>Password</label>
          <div class="input-wrapper">
            <input 
              type="password" 
              v-model="password" 
              required 
              placeholder="Enter your password" 
            />
          </div>
        </div>

        <div v-if="errorMessage" class="error-banner">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          {{ errorMessage }}
        </div>

        <button type="submit" :disabled="isLoading" class="submit-btn">
          <span v-if="isLoading" class="loader"></span>
          <span>{{ isLoading ? 'Authenticating...' : 'Secure Login' }}</span>
        </button>
      </form>
      
      <div class="card-footer">
        <p>គ្រប់គ្រង ERP © 2026</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import axios from 'axios';
import { useRouter } from 'vue-router';

// --- Animated Background Logic ---
const fullText = "គ្រប់គ្រង";
const animatedText = ref("");
let isDeleting = false;
let charIndex = 0;

const typeEffect = () => {
  const currentSpeed = isDeleting ? 100 : 200; 

  if (!isDeleting && charIndex <= fullText.length) {
    animatedText.value = fullText.substring(0, charIndex);
    charIndex++;
    setTimeout(typeEffect, currentSpeed);
  } else if (isDeleting && charIndex >= 0) {
    animatedText.value = fullText.substring(0, charIndex);
    charIndex--;
    setTimeout(typeEffect, currentSpeed);
  } else {
    isDeleting = !isDeleting;
    setTimeout(typeEffect, isDeleting ? 1500 : 500); 
  }
};

onMounted(() => {
  typeEffect(); 
});

// --- Login Logic ---
const username = ref('');
const password = ref('');
const errorMessage = ref('');
const isLoading = ref(false);
const router = useRouter();

const handleLogin = async () => {
  isLoading.value = true;
  errorMessage.value = '';

  try {
    const response = await axios.post('http://localhost:3000/auth/login', {
      username: username.value,
      password: password.value,
    });
    localStorage.setItem('access_token', response.data.access_token);
    router.push('/');   
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Failed to login. Please try again.';
  } finally {
    isLoading.value = false;
  }
};

// --- Dragging Logic ---
const position = ref({ x: 0, y: 0 });
const isDragging = ref(false);
const dragOffset = { x: 0, y: 0 };

const startDrag = (event: MouseEvent) => {
  isDragging.value = true;
  dragOffset.x = event.clientX - position.value.x;
  dragOffset.y = event.clientY - position.value.y;
  
  document.addEventListener('mousemove', onDrag);
  document.addEventListener('mouseup', stopDrag);
};

const onDrag = (event: MouseEvent) => {
  if (!isDragging.value) return;
  position.value.x = event.clientX - dragOffset.x;
  position.value.y = event.clientY - dragOffset.y;
};

const stopDrag = () => {
  isDragging.value = false;
  document.removeEventListener('mousemove', onDrag);
  document.removeEventListener('mouseup', stopDrag);
};

const boxStyle = computed(() => ({
  transform: `translate(${position.value.x}px, ${position.value.y}px)`,
}));
</script>

<style scoped>

.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 1rem;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  overflow: hidden; 
  position: relative;
  

  background-image: 
    linear-gradient(rgba(33, 43, 99, 0.6), rgba(33, 43, 99, 0.85)), 
    url('../../assets/img/LoginBG.png'); 
  background-size: cover;       
  background-position: center;  
  background-repeat: no-repeat; 
}


.animated-bg-text {
  position: absolute;
  top: 15%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 10vw; 
  font-weight: 350;
  color: rgba(255, 255, 255, 0.4); 
  white-space: nowrap;
  pointer-events: none; 
  z-index: 1; 
  font-family: 'Kantumruy Pro', 'Suwannaphum', 'Hanuman', sans-serif; 
}


.blinking-cursor {
  font-weight: 100;
  color: rgba(255, 255, 255, 0.2);
  animation: blink 1s step-end infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}


.login-box {
  background: #ffffff;
  padding: 3rem 2.5rem; 
  border-radius: 16px;
  box-shadow: 0 25px 50px -12px rgba(15, 20, 50, 0.5); /* Shadow tinted with navy */
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  transition: box-shadow 0.2s ease;
  z-index: 10; 
  position: relative;
}


.brand-header {
  text-align: center;
  margin-bottom: 2rem;
  cursor: grab; 
  user-select: none; 
  padding-bottom: 0.5rem; 
}
.brand-header.is-grabbing {
  cursor: grabbing; 
}

.brand-header h2 {
  color: #283375;
  font-size: 1.75rem;
  font-weight: 800;
  margin: 0 0 0.5rem 0;
  letter-spacing: -0.025em;
}
.subtitle {
  color: #64748b;
  font-size: 0.9rem;
  margin: 0;
}


.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}
.input-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 600;
  color: #283375;
  margin-bottom: 0.5rem;
}
.input-wrapper input {
  width: 100%;
  padding: 0.875rem 1rem;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 1rem;
  color: #1e293b;
  background-color: #f8fafc;
  transition: all 0.2s ease;
  box-sizing: border-box;
}
.input-wrapper input:focus {
  outline: none;
  border-color: #4B6BB3; 
  background-color: #ffffff;
  box-shadow: 0 0 0 4px rgba(75, 107, 179, 0.15); 
}
.input-wrapper input::placeholder {
  color: #94a3b8;
}


.submit-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  width: 100%;
  padding: 0.875rem;
  background-color: #283375; 
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s ease, transform 0.1s ease;
  margin-top: 0.5rem;
}
.submit-btn:hover:not(:disabled) {
  background-color: #1a2254;
}
.submit-btn:active:not(:disabled) {
  transform: translateY(1px);
}
.submit-btn:disabled {
  background-color: #74A7E6; 
  cursor: not-allowed;
}


.error-banner {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background-color: #fef2f2;
  color: #dc2626;
  padding: 0.75rem 1rem;
  border-radius: 8px;
  font-size: 0.875rem;
  font-weight: 500;
  border: 1px solid #fecaca;
}


.loader {
  width: 16px;
  height: 16px;
  border: 2px solid #ffffff;
  border-bottom-color: transparent;
  border-radius: 50%;
  display: inline-block;
  box-sizing: border-box;
  animation: rotation 1s linear infinite;
}
@keyframes rotation {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}


.card-footer {
  margin-top: 2rem;
  text-align: center;
  font-size: 0.75rem;
  color: #94a3b8;
}
</style>