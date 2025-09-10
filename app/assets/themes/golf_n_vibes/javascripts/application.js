// Golf n Vibes Theme JavaScript
// Premium golf tour website theme for Spree Commerce

// Theme initialization
document.addEventListener('DOMContentLoaded', function() {
  initializeTheme();
  initializeHeroSection();
  initializeFlashMessages();
  initializeAccessibility();
});

// Main theme initialization
function initializeTheme() {
  console.log('Golf n Vibes theme initialized');
  
  // Add theme-specific classes
  document.body.classList.add('golf-n-vibes-theme');
  
  // Initialize dark mode toggle if present
  initializeDarkMode();
  
  // Initialize responsive navigation
  initializeNavigation();
}

// Hero section enhancements
function initializeHeroSection() {
  const heroSection = document.querySelector('.hero-section');
  if (!heroSection) return;
  
  // Add intersection observer for animations
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-in');
        }
      });
    }, { threshold: 0.1 });
    
    observer.observe(heroSection);
  }
  
  // Add parallax effect to decorative elements (if reduced motion is not preferred)
  if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    initializeParallax();
  }
}

// Parallax effect for decorative elements
function initializeParallax() {
  const parallaxElements = document.querySelectorAll('.hero-section [class*="absolute"]');
  
  window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const rate = scrolled * -0.5;
    
    parallaxElements.forEach(element => {
      if (element.classList.contains('blur-xl') || element.classList.contains('blur-lg')) {
        element.style.transform = `translate3d(0, ${rate}px, 0)`;
      }
    });
  });
}

// Dark mode functionality
function initializeDarkMode() {
  const darkModeToggle = document.querySelector('.dark-mode-toggle');
  if (!darkModeToggle) return;
  
  // Check for saved theme preference or default to system preference
  const theme = localStorage.getItem('theme') || 
                (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  
  // Apply theme
  if (theme === 'dark') {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }
  
  // Toggle event listener
  darkModeToggle.addEventListener('click', () => {
    const isDark = document.documentElement.classList.contains('dark');
    
    if (isDark) {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    } else {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    }
  });
}

// Navigation enhancements
function initializeNavigation() {
  const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
  const mobileMenu = document.querySelector('.mobile-menu');
  
  if (mobileMenuToggle && mobileMenu) {
    mobileMenuToggle.addEventListener('click', () => {
      const isOpen = mobileMenu.classList.contains('open');
      
      if (isOpen) {
        mobileMenu.classList.remove('open');
        mobileMenuToggle.setAttribute('aria-expanded', 'false');
      } else {
        mobileMenu.classList.add('open');
        mobileMenuToggle.setAttribute('aria-expanded', 'true');
      }
    });
    
    // Close mobile menu when clicking outside
    document.addEventListener('click', (e) => {
      if (!mobileMenu.contains(e.target) && !mobileMenuToggle.contains(e.target)) {
        mobileMenu.classList.remove('open');
        mobileMenuToggle.setAttribute('aria-expanded', 'false');
      }
    });
  }
}

// Flash message handling
function initializeFlashMessages() {
  const flashMessages = document.querySelectorAll('.flash-message');
  
  flashMessages.forEach(message => {
    // Auto-hide success messages after 5 seconds
    if (message.classList.contains('flash-notice') || message.classList.contains('flash-success')) {
      setTimeout(() => {
        hideFlashMessage(message);
      }, 5000);
    }
    
    // Close button functionality
    const closeButton = message.querySelector('.flash-close');
    if (closeButton) {
      closeButton.addEventListener('click', () => {
        hideFlashMessage(message);
      });
    }
  });
}

// Hide flash message with animation
function hideFlashMessage(message) {
  message.style.transform = 'translateX(100%)';
  message.style.opacity = '0';
  
  setTimeout(() => {
    if (message.parentNode) {
      message.parentNode.removeChild(message);
    }
  }, 300);
}

// Accessibility enhancements
function initializeAccessibility() {
  // Add focus indicators for keyboard navigation
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Tab') {
      document.body.classList.add('keyboard-navigation');
    }
  });
  
  document.addEventListener('mousedown', () => {
    document.body.classList.remove('keyboard-navigation');
  });
  
  // Enhance button accessibility
  const buttons = document.querySelectorAll('button, .btn, [role="button"]');
  buttons.forEach(button => {
    if (!button.hasAttribute('aria-label') && !button.textContent.trim()) {
      console.warn('Button without accessible label found:', button);
    }
  });
  
  // Add skip links for screen readers
  addSkipLinks();
}

// Add skip links for better accessibility
function addSkipLinks() {
  const skipLink = document.querySelector('a[href="#main-content"]');
  if (skipLink) {
    skipLink.addEventListener('click', (e) => {
      e.preventDefault();
      const target = document.querySelector('#main-content');
      if (target) {
        target.focus();
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  }
}

// Utility functions
const GolfNVibesUtils = {
  // Debounce function for performance
  debounce: function(func, wait, immediate) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        timeout = null;
        if (!immediate) func(...args);
      };
      const callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
      if (callNow) func(...args);
    };
  },
  
  // Smooth scroll utility
  smoothScroll: function(target, duration = 1000) {
    const targetElement = typeof target === 'string' ? document.querySelector(target) : target;
    if (!targetElement) return;
    
    const targetPosition = targetElement.offsetTop;
    const startPosition = window.pageYOffset;
    const distance = targetPosition - startPosition;
    let startTime = null;
    
    function animation(currentTime) {
      if (startTime === null) startTime = currentTime;
      const timeElapsed = currentTime - startTime;
      const run = easeInOutQuad(timeElapsed, startPosition, distance, duration);
      window.scrollTo(0, run);
      if (timeElapsed < duration) requestAnimationFrame(animation);
    }
    
    function easeInOutQuad(t, b, c, d) {
      t /= d / 2;
      if (t < 1) return c / 2 * t * t + b;
      t--;
      return -c / 2 * (t * (t - 2) - 1) + b;
    }
    
    requestAnimationFrame(animation);
  },
  
  // Form validation helper
  validateForm: function(form) {
    const errors = [];
    const requiredFields = form.querySelectorAll('[required]');
    
    requiredFields.forEach(field => {
      if (!field.value.trim()) {
        errors.push(`${field.name || field.id} is required`);
        field.classList.add('error');
      } else {
        field.classList.remove('error');
      }
    });
    
    return {
      isValid: errors.length === 0,
      errors: errors
    };
  }
};

// Export utilities for use in other scripts
if (typeof window !== 'undefined') {
  window.GolfNVibesUtils = GolfNVibesUtils;
}

// Performance monitoring (development only)
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
  window.addEventListener('load', () => {
    if ('performance' in window) {
      const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
      console.log(`Golf n Vibes theme loaded in ${loadTime}ms`);
    }
  });
}
