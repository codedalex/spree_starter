/**
 * CRITICAL PAYMENT INTERCEPTOR
 * This script prevents card payments from proceeding without card details
 * Must be loaded BEFORE any payment processing occurs
 */

(function() {
    'use strict';
    
    console.log('🔒 Payment Interceptor: Loading card payment protection');
    
    // Global flag to track if card details have been collected
    window.cardDetailsCollected = false;
    window.collectedCardData = null;
    
    // Store original fetch function
    const originalFetch = window.fetch;
    
    // Intercept all fetch requests
    window.fetch = function(...args) {
        const url = args[0];
        const options = args[1] || {};
        
        // Check if this is a payment request
        if (url && (url.includes('/sasapay/create_order_and_pay') || url.includes('/create_order_and_pay'))) {
            console.log('🚫 Payment Interceptor: Detected payment request to', url);
            
            // Parse the request body
            let requestData;
            try {
                if (options.body) {
                    requestData = JSON.parse(options.body);
                    console.log('🔍 Payment Interceptor: Request data:', requestData);
                }
            } catch (e) {
                console.warn('Payment Interceptor: Could not parse request body', e);
            }
            
            // Check if this is a card payment
            if (requestData && requestData.payment_type === 'card') {
                console.log('💳 Payment Interceptor: Card payment detected');
                
                // Check if card data is missing
                if (!requestData.card_data) {
                    console.log('❌ Payment Interceptor: BLOCKING - No card data found');
                    
                    // Show card details modal instead of proceeding
                    showCardDetailsModal(requestData, options, originalFetch, url);
                    
                    // Return a pending promise that will be resolved after card details are collected
                    return new Promise((resolve, reject) => {
                        window.pendingCardPaymentResolve = resolve;
                        window.pendingCardPaymentReject = reject;
                        window.pendingCardPaymentData = { requestData, options, url };
                    });
                } else {
                    console.log('✅ Payment Interceptor: Card data found, allowing payment to proceed');
                }
            }
        }
        
        // For non-card payments or properly formed card payments, proceed normally
        return originalFetch.apply(this, args);
    };
    
    // Function to show card details modal
    function showCardDetailsModal(requestData, options, originalFetch, url) {
        console.log('🎯 Payment Interceptor: Showing card details modal');
        
        // Create modal if it doesn't exist
        if (!document.getElementById('interceptor-card-modal')) {
            createCardModal();
        }
        
        // Show the modal
        const modal = document.getElementById('interceptor-card-modal');
        modal.style.display = 'flex';
        document.body.style.overflow = 'hidden';
        
        // Focus on card number input
        setTimeout(() => {
            const cardNumberInput = document.getElementById('interceptor-card-number');
            if (cardNumberInput) cardNumberInput.focus();
        }, 100);
    }
    
    // Create card details modal
    function createCardModal() {
        const modalHTML = `
            <div id="interceptor-card-modal" style="
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.8);
                display: none;
                align-items: center;
                justify-content: center;
                z-index: 99999;
                backdrop-filter: blur(4px);
            ">
                <div style="
                    background: white;
                    border-radius: 16px;
                    padding: 2rem;
                    width: 90%;
                    max-width: 500px;
                    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
                    max-height: 90vh;
                    overflow-y: auto;
                ">
                    <div style="
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        margin-bottom: 2rem;
                        padding-bottom: 1rem;
                        border-bottom: 1px solid #e5e7eb;
                    ">
                        <h2 style="
                            font-size: 1.5rem;
                            font-weight: 600;
                            color: #1e293b;
                            margin: 0;
                        ">⚠️ Card Details Required</h2>
                        <button id="interceptor-close-modal" style="
                            background: none;
                            border: none;
                            font-size: 1.5rem;
                            cursor: pointer;
                            color: #6b7280;
                            padding: 0.25rem;
                        ">&times;</button>
                    </div>

                    <div style="
                        background: #fef3c7;
                        border: 1px solid #f59e0b;
                        border-radius: 8px;
                        padding: 1rem;
                        margin-bottom: 1.5rem;
                        color: #92400e;
                    ">
                        🛡️ <strong>Security Check:</strong> You selected card payment but no card details were provided. Please enter your card information to proceed.
                    </div>

                    <form id="interceptor-card-form">
                        <div style="margin-bottom: 1.5rem;">
                            <label style="
                                display: block;
                                font-size: 0.875rem;
                                font-weight: 500;
                                color: #374151;
                                margin-bottom: 0.5rem;
                            ">Card Number *</label>
                            <input 
                                type="text" 
                                id="interceptor-card-number"
                                placeholder="1234 5678 9012 3456" 
                                maxlength="19" 
                                required 
                                style="
                                    width: 100%;
                                    padding: 0.875rem 1rem;
                                    border: 2px solid #e5e7eb;
                                    border-radius: 8px;
                                    font-size: 1rem;
                                    font-family: 'Courier New', monospace;
                                ">
                        </div>
                        
                        <div style="margin-bottom: 1.5rem;">
                            <label style="
                                display: block;
                                font-size: 0.875rem;
                                font-weight: 500;
                                color: #374151;
                                margin-bottom: 0.5rem;
                            ">Cardholder Name *</label>
                            <input 
                                type="text" 
                                id="interceptor-cardholder-name"
                                placeholder="JOHN DOE" 
                                required 
                                style="
                                    width: 100%;
                                    padding: 0.875rem 1rem;
                                    border: 2px solid #e5e7eb;
                                    border-radius: 8px;
                                    font-size: 1rem;
                                    text-transform: uppercase;
                                ">
                        </div>
                        
                        <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 1rem;">
                            <div style="margin-bottom: 1.5rem;">
                                <label style="
                                    display: block;
                                    font-size: 0.875rem;
                                    font-weight: 500;
                                    color: #374151;
                                    margin-bottom: 0.5rem;
                                ">Expiry Date *</label>
                                <input 
                                    type="text" 
                                    id="interceptor-expiry"
                                    placeholder="MM/YY" 
                                    maxlength="5" 
                                    required 
                                    style="
                                        width: 100%;
                                        padding: 0.875rem 1rem;
                                        border: 2px solid #e5e7eb;
                                        border-radius: 8px;
                                        font-size: 1rem;
                                        font-family: 'Courier New', monospace;
                                    ">
                            </div>
                            <div style="margin-bottom: 1.5rem;">
                                <label style="
                                    display: block;
                                    font-size: 0.875rem;
                                    font-weight: 500;
                                    color: #374151;
                                    margin-bottom: 0.5rem;
                                ">CVV *</label>
                                <input 
                                    type="text" 
                                    id="interceptor-cvv"
                                    placeholder="123" 
                                    maxlength="4" 
                                    required 
                                    style="
                                        width: 100%;
                                        padding: 0.875rem 1rem;
                                        border: 2px solid #e5e7eb;
                                        border-radius: 8px;
                                        font-size: 1rem;
                                        font-family: 'Courier New', monospace;
                                    ">
                            </div>
                        </div>

                        <div style="
                            background: #f0f9ff;
                            border: 1px solid #bae6fd;
                            border-radius: 8px;
                            padding: 1rem;
                            margin: 1.5rem 0;
                            font-size: 0.875rem;
                            color: #0369a1;
                        ">
                            🔒 Your card information is encrypted and secure. This payment is processed by SasaPay.
                        </div>

                        <div style="display: flex; gap: 1rem; margin-top: 2rem;">
                            <button 
                                type="button" 
                                id="interceptor-cancel" 
                                style="
                                    flex: 1;
                                    padding: 0.875rem 1.5rem;
                                    border-radius: 8px;
                                    font-size: 1rem;
                                    font-weight: 600;
                                    cursor: pointer;
                                    background: #f3f4f6;
                                    color: #374151;
                                    border: 1px solid #d1d5db;
                                ">Cancel Payment</button>
                            <button 
                                type="submit"
                                style="
                                    flex: 1;
                                    padding: 0.875rem 1.5rem;
                                    border-radius: 8px;
                                    font-size: 1rem;
                                    font-weight: 600;
                                    cursor: pointer;
                                    background: #dc2626;
                                    color: white;
                                    border: none;
                                ">Continue Payment</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHTML);
        
        // Add event listeners
        setupModalEventListeners();
    }
    
    // Setup modal event listeners
    function setupModalEventListeners() {
        // Close modal
        document.getElementById('interceptor-close-modal').addEventListener('click', cancelPayment);
        document.getElementById('interceptor-cancel').addEventListener('click', cancelPayment);
        
        // Card number formatting
        document.getElementById('interceptor-card-number').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\s/g, '').replace(/[^0-9]/gi, '');
            let formattedValue = value.match(/.{1,4}/g)?.join(' ') || value;
            if (value.length <= 16) {
                e.target.value = formattedValue;
            }
        });
        
        // Expiry formatting
        document.getElementById('interceptor-expiry').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            if (value.length >= 2) {
                value = value.substring(0,2) + '/' + value.substring(2,4);
            }
            e.target.value = value;
        });
        
        // CVV formatting
        document.getElementById('interceptor-cvv').addEventListener('input', function(e) {
            e.target.value = e.target.value.replace(/[^0-9]/g, '');
        });
        
        // Form submission
        document.getElementById('interceptor-card-form').addEventListener('submit', function(e) {
            e.preventDefault();
            handleCardDetailsSubmission();
        });
    }
    
    // Handle card details submission
    function handleCardDetailsSubmission() {
        console.log('💳 Payment Interceptor: Processing card details');
        
        const cardNumber = document.getElementById('interceptor-card-number').value.replace(/\s/g, '');
        const cardholderName = document.getElementById('interceptor-cardholder-name').value.toUpperCase();
        const expiry = document.getElementById('interceptor-expiry').value;
        const cvv = document.getElementById('interceptor-cvv').value;
        
        // Validate fields
        if (!cardNumber || !cardholderName || !expiry || !cvv) {
            alert('❌ All card fields are required');
            return;
        }
        
        if (cardNumber.length < 13 || cardNumber.length > 19) {
            alert('❌ Please enter a valid card number');
            return;
        }
        
        if (!expiry.match(/^(0[1-9]|1[0-2])\/\d{2}$/)) {
            alert('❌ Please enter a valid expiry date (MM/YY)');
            return;
        }
        
        if (cvv.length < 3 || cvv.length > 4) {
            alert('❌ Please enter a valid CVV');
            return;
        }
        
        // Parse expiry
        const expiryParts = expiry.split('/');
        const cardData = {
            card_number: cardNumber,
            cardholder_name: cardholderName,
            expiry_month: expiryParts[0],
            expiry_year: '20' + expiryParts[1],
            cvv: cvv
        };
        
        console.log('✅ Payment Interceptor: Card data collected, proceeding with payment');
        
        // Hide modal
        hideModal();
        
        // Add card data to the original request and proceed
        if (window.pendingCardPaymentData && window.pendingCardPaymentResolve) {
            const { requestData, options, url } = window.pendingCardPaymentData;
            
            // Add card data to request
            requestData.card_data = cardData;
            options.body = JSON.stringify(requestData);
            
            console.log('🚀 Payment Interceptor: Executing payment with card data');
            
            // Execute the original fetch with card data
            originalFetch(url, options)
                .then(response => {
                    console.log('✅ Payment Interceptor: Payment request completed');
                    window.pendingCardPaymentResolve(response);
                })
                .catch(error => {
                    console.error('❌ Payment Interceptor: Payment request failed', error);
                    window.pendingCardPaymentReject(error);
                })
                .finally(() => {
                    // Clean up
                    window.pendingCardPaymentData = null;
                    window.pendingCardPaymentResolve = null;
                    window.pendingCardPaymentReject = null;
                });
        }
    }
    
    // Cancel payment
    function cancelPayment() {
        console.log('❌ Payment Interceptor: Payment cancelled by user');
        hideModal();
        
        if (window.pendingCardPaymentReject) {
            window.pendingCardPaymentReject(new Error('Payment cancelled by user'));
            window.pendingCardPaymentData = null;
            window.pendingCardPaymentResolve = null;
            window.pendingCardPaymentReject = null;
        }
    }
    
    // Hide modal
    function hideModal() {
        const modal = document.getElementById('interceptor-card-modal');
        if (modal) {
            modal.style.display = 'none';
            document.body.style.overflow = 'auto';
        }
    }
    
    console.log('✅ Payment Interceptor: Loaded successfully - All card payments will be intercepted');
    
})();
