/**
 * FRONTEND PAYMENT HANDLER
 * This must be integrated into your React checkout component
 * Copy this logic into your RealSasaPayCheckout.tsx file
 */

// Step 1: Add this state to your React component
const checkoutPaymentState = {
  isCardModalOpen: false,
  cardData: null,
  isProcessing: false
};

// Step 2: Replace your current payment submission logic with this
async function handlePaymentSubmit(paymentType, orderData) {
  console.log('Payment submit started with type:', paymentType);
  
  // CRITICAL: Check if card payment and card data is missing
  if (paymentType === 'card' && !orderData.card_data) {
    console.log('Card payment detected - showing card details modal');
    
    // Show card details modal and wait for user input
    const cardData = await showCardDetailsModal();
    
    if (!cardData) {
      console.log('Card payment cancelled');
      return { status: 'cancelled', message: 'Payment cancelled' };
    }
    
    // Add card data to order
    orderData.card_data = cardData;
    console.log('Card data collected, proceeding with payment');
  }
  
  // Now proceed with the actual payment API call
  return await processPayment(orderData);
}

// Step 3: Card details modal function
function showCardDetailsModal() {
  return new Promise((resolve, reject) => {
    // Create modal HTML
    const modalHTML = `
      <div id="card-details-modal" style="
        position: fixed; top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(0,0,0,0.8); display: flex; align-items: center;
        justify-content: center; z-index: 10000;
      ">
        <div style="
          background: white; border-radius: 12px; padding: 2rem;
          width: 90%; max-width: 500px; box-shadow: 0 20px 40px rgba(0,0,0,0.3);
        ">
          <h2 style="margin-bottom: 1.5rem; color: #1e293b; font-weight: 600;">
            Enter Card Details
          </h2>
          
          <form id="card-form">
            <div style="margin-bottom: 1rem;">
              <label style="display: block; margin-bottom: 0.5rem; font-weight: 500;">
                Card Number *
              </label>
              <input 
                type="text" 
                id="card-number" 
                placeholder="1234 5678 9012 3456"
                maxlength="19"
                required
                style="
                  width: 100%; padding: 0.75rem; border: 2px solid #e5e7eb;
                  border-radius: 8px; font-size: 1rem; font-family: monospace;
                "
              />
            </div>
            
            <div style="margin-bottom: 1rem;">
              <label style="display: block; margin-bottom: 0.5rem; font-weight: 500;">
                Cardholder Name *
              </label>
              <input 
                type="text" 
                id="cardholder-name" 
                placeholder="JOHN DOE"
                required
                style="
                  width: 100%; padding: 0.75rem; border: 2px solid #e5e7eb;
                  border-radius: 8px; font-size: 1rem; text-transform: uppercase;
                "
              />
            </div>
            
            <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 1rem; margin-bottom: 1rem;">
              <div>
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 500;">
                  Expiry Date *
                </label>
                <input 
                  type="text" 
                  id="expiry-date" 
                  placeholder="MM/YY"
                  maxlength="5"
                  required
                  style="
                    width: 100%; padding: 0.75rem; border: 2px solid #e5e7eb;
                    border-radius: 8px; font-size: 1rem; font-family: monospace;
                  "
                />
              </div>
              <div>
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 500;">
                  CVV *
                </label>
                <input 
                  type="text" 
                  id="cvv" 
                  placeholder="123"
                  maxlength="4"
                  required
                  style="
                    width: 100%; padding: 0.75rem; border: 2px solid #e5e7eb;
                    border-radius: 8px; font-size: 1rem; font-family: monospace;
                  "
                />
              </div>
            </div>
            
            <div style="
              background: #f0f9ff; border: 1px solid #bae6fd; border-radius: 8px;
              padding: 1rem; margin: 1rem 0; font-size: 0.9rem; color: #0369a1;
            ">
              🔒 Your payment is secure and encrypted by SasaPay
            </div>
            
            <div style="display: flex; gap: 1rem; margin-top: 1.5rem;">
              <button 
                type="button" 
                id="cancel-card-payment"
                style="
                  flex: 1; padding: 0.75rem; background: #f3f4f6; color: #374151;
                  border: 1px solid #d1d5db; border-radius: 8px; cursor: pointer;
                "
              >
                Cancel
              </button>
              <button 
                type="submit"
                style="
                  flex: 1; padding: 0.75rem; background: #dc2626; color: white;
                  border: none; border-radius: 8px; cursor: pointer; font-weight: 600;
                "
              >
                Continue Payment
              </button>
            </div>
          </form>
        </div>
      </div>
    `;
    
    // Add modal to DOM
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    document.body.style.overflow = 'hidden';
    
    // Add formatting for inputs
    const cardNumberInput = document.getElementById('card-number');
    cardNumberInput.addEventListener('input', function(e) {
      let value = e.target.value.replace(/\s/g, '').replace(/[^0-9]/gi, '');
      let formatted = value.match(/.{1,4}/g)?.join(' ') || value;
      if (value.length <= 16) e.target.value = formatted;
    });
    
    const expiryInput = document.getElementById('expiry-date');
    expiryInput.addEventListener('input', function(e) {
      let value = e.target.value.replace(/\D/g, '');
      if (value.length >= 2) {
        value = value.substring(0,2) + '/' + value.substring(2,4);
      }
      e.target.value = value;
    });
    
    const cvvInput = document.getElementById('cvv');
    cvvInput.addEventListener('input', function(e) {
      e.target.value = e.target.value.replace(/[^0-9]/g, '');
    });
    
    // Handle form submission
    document.getElementById('card-form').addEventListener('submit', function(e) {
      e.preventDefault();
      
      const cardNumber = document.getElementById('card-number').value.replace(/\s/g, '');
      const cardholderName = document.getElementById('cardholder-name').value.toUpperCase();
      const expiryDate = document.getElementById('expiry-date').value;
      const cvv = document.getElementById('cvv').value;
      
      // Validation
      if (!cardNumber || cardNumber.length < 13 || cardNumber.length > 19) {
        alert('Please enter a valid card number');
        return;
      }
      
      if (!cardholderName || cardholderName.length < 2) {
        alert('Please enter the cardholder name');
        return;
      }
      
      if (!expiryDate.match(/^(0[1-9]|1[0-2])\/\d{2}$/)) {
        alert('Please enter a valid expiry date (MM/YY)');
        return;
      }
      
      if (!cvv || cvv.length < 3) {
        alert('Please enter a valid CVV');
        return;
      }
      
      // Parse expiry
      const [month, year] = expiryDate.split('/');
      const cardData = {
        card_number: cardNumber,
        cardholder_name: cardholderName,
        expiry_month: month,
        expiry_year: '20' + year,
        cvv: cvv
      };
      
      // Clean up modal
      document.getElementById('card-details-modal').remove();
      document.body.style.overflow = 'auto';
      
      resolve(cardData);
    });
    
    // Handle cancel
    document.getElementById('cancel-card-payment').addEventListener('click', function() {
      document.getElementById('card-details-modal').remove();
      document.body.style.overflow = 'auto';
      resolve(null);
    });
    
    // Focus on first input
    setTimeout(() => cardNumberInput.focus(), 100);
  });
}

// Step 4: Updated payment processing function
async function processPayment(orderData) {
  try {
    console.log('Making payment API call with data:', orderData);
    
    const response = await fetch('/api/v2/storefront/sasapay/create_order_and_pay', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
      },
      body: JSON.stringify(orderData)
    });
    
    const result = await response.json();
    
    if (result.status === 'success') {
      console.log('Payment successful:', result);
      return {
        status: 'success',
        message: `Payment successful! Order #${result.order_number}`,
        order_number: result.order_number,
        payment_url: result.payment_url
      };
    } else {
      console.error('Payment failed:', result);
      return {
        status: 'error',
        message: result.message || 'Payment failed'
      };
    }
    
  } catch (error) {
    console.error('Payment error:', error);
    return {
      status: 'error',
      message: 'Network error: ' + error.message
    };
  }
}

// Step 5: Integration example for React component
/*
// In your React component (RealSasaPayCheckout.tsx):

const handleSubmit = async (e) => {
  e.preventDefault();
  setIsLoading(true);
  
  try {
    const orderData = {
      items: cartItems,
      customer_data: formData,
      payment_type: selectedPaymentMethod,
      phone_number: formData.phone
      // Note: card_data will be added by handlePaymentSubmit if needed
    };
    
    const result = await handlePaymentSubmit(selectedPaymentMethod, orderData);
    
    if (result.status === 'success') {
      // Handle success
      if (result.payment_url) {
        window.location.href = result.payment_url;
      } else {
        showSuccessMessage(result.message);
      }
    } else if (result.status === 'cancelled') {
      // User cancelled payment
      console.log('Payment cancelled by user');
    } else {
      // Handle error
      showErrorMessage(result.message);
    }
    
  } catch (error) {
    showErrorMessage('Payment failed: ' + error.message);
  } finally {
    setIsLoading(false);
  }
};
*/

console.log('✅ Checkout Payment Handler loaded - Card payments will require card details');

// Export for module use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { handlePaymentSubmit, showCardDetailsModal, processPayment };
}
