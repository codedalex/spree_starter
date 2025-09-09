// Modern Checkout Payment Handler
class CheckoutPaymentHandler {
    constructor() {
        this.selectedPaymentMethod = 'mpesa';
        this.orderData = {
            items: [],
            customer_data: {},
            payment_type: 'mpesa'
        };
        
        this.init();
    }

    init() {
        this.setupPaymentMethodSelection();
        this.setupCardFormatting();
        this.setupFormValidation();
        this.setupCheckoutButton();
    }

    setupPaymentMethodSelection() {
        const paymentOptions = document.querySelectorAll('.payment-option');
        
        paymentOptions.forEach(option => {
            option.addEventListener('click', (e) => {
                // Remove selected class from all options
                paymentOptions.forEach(opt => opt.classList.remove('selected'));
                
                // Add selected class to clicked option
                option.classList.add('selected');
                
                // Update selected payment method
                this.selectedPaymentMethod = option.dataset.payment;
                this.orderData.payment_type = this.selectedPaymentMethod;
                
                // Update button text
                this.updateCheckoutButton();
            });
        });
    }

    setupCardFormatting() {
        const cardNumber = document.getElementById('card-number');
        const expiryDate = document.getElementById('card-expiry');
        const cvv = document.getElementById('card-cvv');

        if (cardNumber) {
            cardNumber.addEventListener('input', (e) => {
                let value = e.target.value.replace(/\s/g, '').replace(/[^0-9]/gi, '');
                let formattedValue = value.match(/.{1,4}/g)?.join(' ') || value;
                if (value.length <= 16) {
                    e.target.value = formattedValue;
                }
            });
        }

        if (expiryDate) {
            expiryDate.addEventListener('input', (e) => {
                let value = e.target.value.replace(/\D/g, '');
                if (value.length >= 2) {
                    value = value.substring(0,2) + '/' + value.substring(2,4);
                }
                e.target.value = value;
            });
        }

        if (cvv) {
            cvv.addEventListener('input', (e) => {
                e.target.value = e.target.value.replace(/[^0-9]/g, '');
            });
        }
    }

    setupFormValidation() {
        const form = document.getElementById('checkout-form');
        if (!form) return;

        const requiredFields = form.querySelectorAll('[required]');
        
        requiredFields.forEach(field => {
            field.addEventListener('blur', () => {
                this.validateField(field);
            });
        });
    }

    validateField(field) {
        const isValid = field.value.trim() !== '';
        
        if (isValid) {
            field.classList.remove('error');
        } else {
            field.classList.add('error');
        }
        
        return isValid;
    }

    validateCardData() {
        if (this.selectedPaymentMethod !== 'card') return true;

        const cardNumber = document.getElementById('card-number')?.value.replace(/\s/g, '');
        const expiryDate = document.getElementById('card-expiry')?.value;
        const cvv = document.getElementById('card-cvv')?.value;
        const cardName = document.getElementById('card-name')?.value;

        if (!cardNumber || cardNumber.length < 13 || cardNumber.length > 19) {
            alert('Please enter a valid card number');
            return false;
        }

        if (!expiryDate || !expiryDate.match(/^(0[1-9]|1[0-2])\/\d{2}$/)) {
            alert('Please enter a valid expiry date (MM/YY)');
            return false;
        }

        if (!cvv || cvv.length < 3 || cvv.length > 4) {
            alert('Please enter a valid CVV');
            return false;
        }

        if (!cardName || cardName.trim().length < 2) {
            alert('Please enter the cardholder name');
            return false;
        }

        return true;
    }

    validateMpesaData() {
        if (this.selectedPaymentMethod !== 'mpesa') return true;

        const phoneNumber = document.getElementById('mpesa-phone')?.value;
        
        if (!phoneNumber || !phoneNumber.match(/^(\+254|254|0)[17]\d{8}$/)) {
            alert('Please enter a valid M-Pesa phone number');
            return false;
        }

        return true;
    }

    collectOrderData() {
        // Customer data
        this.orderData.customer_data = {
            email: document.getElementById('email')?.value || '',
            firstName: document.getElementById('firstName')?.value || '',
            lastName: document.getElementById('lastName')?.value || '',
            phone: document.getElementById('phone')?.value || '',
            address: document.getElementById('address')?.value || '',
            city: document.getElementById('city')?.value || 'Nairobi'
        };

        // Phone number for payment
        if (this.selectedPaymentMethod === 'mpesa') {
            this.orderData.phone_number = document.getElementById('mpesa-phone')?.value || this.orderData.customer_data.phone;
        } else {
            this.orderData.phone_number = this.orderData.customer_data.phone;
        }

        // Card data if card payment
        if (this.selectedPaymentMethod === 'card') {
            const expiryParts = document.getElementById('card-expiry').value.split('/');
            this.orderData.card_data = {
                card_number: document.getElementById('card-number').value.replace(/\s/g, ''),
                expiry_month: expiryParts[0],
                expiry_year: '20' + expiryParts[1],
                cvv: document.getElementById('card-cvv').value,
                cardholder_name: document.getElementById('card-name').value
            };
        }

        // Default items (you can make this dynamic)
        this.orderData.items = [
            { product_id: "3", quantity: 1 },
            { product_id: "7", quantity: 1 }
        ];

        return this.orderData;
    }

    updateCheckoutButton() {
        const button = document.getElementById('checkout-btn');
        if (!button) return;

        const buttonTexts = {
            'mpesa': 'Pay with M-Pesa',
            'card': 'Pay with Card',
            'cod': 'Place Order (COD)'
        };

        button.textContent = buttonTexts[this.selectedPaymentMethod] || 'Complete Order';
    }

    setupCheckoutButton() {
        const button = document.getElementById('checkout-btn');
        if (!button) return;

        button.addEventListener('click', (e) => {
            e.preventDefault();
            this.processCheckout();
        });
    }

    async processCheckout() {
        const button = document.getElementById('checkout-btn');
        
        // Disable button
        button.disabled = true;
        button.textContent = 'Processing...';

        try {
            // Validate based on payment method
            if (!this.validateCardData() || !this.validateMpesaData()) {
                return;
            }

            // Collect order data
            const orderData = this.collectOrderData();

            // Validate required fields
            if (!orderData.customer_data.email || !orderData.customer_data.firstName || !orderData.customer_data.lastName) {
                alert('Please fill in all required fields');
                return;
            }

            // Submit order
            const response = await fetch('/api/v2/storefront/sasapay/create_order_and_pay', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': this.getCSRFToken()
                },
                body: JSON.stringify(orderData)
            });

            const result = await response.json();

            if (result.status === 'success') {
                this.handleSuccessResponse(result);
            } else {
                alert(`Error: ${result.message || 'Unknown error occurred'}`);
            }

        } catch (error) {
            console.error('Checkout error:', error);
            alert('An error occurred while processing your order. Please try again.');
        } finally {
            // Re-enable button
            button.disabled = false;
            this.updateCheckoutButton();
        }
    }

    handleSuccessResponse(result) {
        const messages = {
            'mpesa': `M-Pesa STK push sent! Check your phone to complete payment for order #${result.order_number}`,
            'card': `Card payment initiated successfully! Order #${result.order_number}`,
            'cod': `Order placed successfully! Order #${result.order_number}. Payment will be collected on delivery.`
        };

        alert(messages[this.selectedPaymentMethod] || `Order placed successfully! Order #${result.order_number}`);

        // Redirect if payment URL provided (for card payments)
        if (result.payment_url) {
            window.location.href = result.payment_url;
        } else {
            // Redirect to thank you page or order status
            window.location.href = `/orders/${result.order_number}` || '/thank-you';
        }
    }

    getCSRFToken() {
        const meta = document.querySelector('meta[name="csrf-token"]');
        return meta ? meta.getAttribute('content') : '';
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new CheckoutPaymentHandler();
});

// Utility functions for formatting
window.formatCardNumber = function(input) {
    let value = input.value.replace(/\s/g, '').replace(/[^0-9]/gi, '');
    let formattedValue = value.match(/.{1,4}/g)?.join(' ') || value;
    if (value.length <= 16) {
        input.value = formattedValue;
    }
};

window.formatExpiryDate = function(input) {
    let value = input.value.replace(/\D/g, '');
    if (value.length >= 2) {
        value = value.substring(0,2) + '/' + value.substring(2,4);
    }
    input.value = value;
};

window.formatCVV = function(input) {
    input.value = input.value.replace(/[^0-9]/g, '');
};
