// EventLive Client-side Logic
document.addEventListener('DOMContentLoaded', () => {
    console.log('EventLive Platform Initialized');

    // Centralized UI Initialization
    initCommonUI();

    // Helper to get dynamic future dates
    function getFutureDate(daysToAdd) {
        const date = new Date();
        date.setDate(date.getDate() + daysToAdd);
        return date.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
    }

    // Default Events Data
    const defaultEvents = [
        {
            id: 1,
            title: "24H Hackathon",
            category: "General",
            date: getFutureDate(3),
            location: "Vel Tech, Avadi",
            price: "₹299.00",
            image: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80",
            isLogo: false
        },
        {
            id: 3,
            title: "Neon Pulse Festival",
            category: "Music & Arts",
            date: getFutureDate(5),
            location: "Los Angeles, CA",
            price: "₹399.00",
            image: "images/music_event.png",
            isLogo: false
        },
        {
            id: 4,
            title: "Future AI & Web3 Summit",
            category: "Technology",
            date: getFutureDate(7),
            location: "San Francisco, CA",
            price: "₹499.00",
            image: "images/tech_event.png",
            isLogo: false
        },
        {
            id: 5,
            title: "Global Esports Finals",
            category: "Sports",
            date: getFutureDate(9),
            location: "Austin, TX",
            price: "₹299.00",
            image: "images/hero_bg.png",
            isLogo: false
        }
    ];

    // Initialize LocalStorage with default events IF empty
    if (!localStorage.getItem('eventlive_events')) {
        localStorage.setItem('eventlive_events', JSON.stringify(defaultEvents));
    }

    // Auto-update existing events dynamically & Remove LAVAZA (id: 2)
    let storedEvents = JSON.parse(localStorage.getItem('eventlive_events') || '[]');
    let eventsChanged = false;

    // Filter out LAVAZA
    const initialLen = storedEvents.length;
    storedEvents = storedEvents.filter(e => e.id !== 2);
    if (storedEvents.length !== initialLen) eventsChanged = true;

    // Auto-update dates for default events relative to today
    const daysOffset = { 1: 3, 3: 5, 4: 7, 5: 9 };
    storedEvents = storedEvents.map(event => {
        if (daysOffset[event.id]) {
            const newDate = getFutureDate(daysOffset[event.id]);
            if (event.date !== newDate) {
                event.date = newDate;
                eventsChanged = true;
            }
        }
        return event;
    });

    if (eventsChanged) {
        localStorage.setItem('eventlive_events', JSON.stringify(storedEvents));
    }

    const eventsGrid = document.querySelector('.events-grid');

    // Intersection Observer for scroll animations
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.1 });

    function renderEvents() {
        if (!eventsGrid) return;
        const events = JSON.parse(localStorage.getItem('eventlive_events') || '[]');
        eventsGrid.innerHTML = '';

        events.forEach(event => {
            const card = document.createElement('div');
            card.className = 'event-card';
            card.innerHTML = `
                <img src="${event.image}" alt="${event.title}" class="event-img ${event.isLogo ? 'logo-img' : ''}">
                <div class="event-info">
                    <span class="event-category">${event.category}</span>
                    <h3 class="event-title">${event.title}</h3>
                    <div class="event-details" style="margin-bottom: 0.5rem;">
                        <span>${event.date}</span>
                        <span>${event.location}</span>
                    </div>
                    <div class="event-details">
                        <span class="price">${event.price}</span>
                    </div>
                    <a href="#" class="ticket-btn">Get Tickets</a>
                </div>
            `;
            eventsGrid.appendChild(card);

            card.style.opacity = '0';
            card.style.transform = 'translateY(30px)';
            card.style.transition = 'all 0.6s ease-out';
            observer.observe(card);
        });
    }

    renderEvents();

    // Booking Modal Logic
    const bookingModal = document.getElementById('booking-modal');
    if (bookingModal) {
        const closeModal = document.getElementById('close-modal');
        const ticketQtyInput = document.getElementById('ticket-qty');
        const totalPriceDisplay = document.getElementById('total-price-display');
        const modalEventName = document.getElementById('modal-event-name');
        const modalPriceInfo = document.getElementById('modal-ticket-price-info');
        const checkoutBtn = document.getElementById('checkout-btn');

        let currentEventPrice = 0;

        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('ticket-btn')) {
                e.preventDefault();
                const card = e.target.closest('.event-card');
                const eventTitle = card.querySelector('.event-title').innerText;
                const priceText = card.querySelector('.price').innerText;
                currentEventPrice = parseFloat(priceText.replace(/[^\d.]/g, ''));

                modalEventName.innerText = eventTitle;
                modalPriceInfo.innerText = `${priceText} - 1995 available`;
                ticketQtyInput.value = 0;
                totalPriceDisplay.innerText = `Total: ₹0.00`;

                bookingModal.style.display = 'flex';
            }
        });

        if (closeModal) {
            closeModal.addEventListener('click', () => {
                bookingModal.style.display = 'none';
            });
        }

        if (ticketQtyInput) {
            ticketQtyInput.addEventListener('input', () => {
                const qty = parseInt(ticketQtyInput.value) || 0;
                const total = (qty * currentEventPrice).toFixed(2);
                totalPriceDisplay.innerText = `Total: ₹${total}`;
            });
        }

        if (checkoutBtn) {
            checkoutBtn.addEventListener('click', () => {
                const qty = parseInt(ticketQtyInput.value) || 0;
                if (qty > 0) {
                    const eventTitle = modalEventName.innerText;
                    const price = currentEventPrice;
                    window.location.href = `payment.html?event=${encodeURIComponent(eventTitle)}&price=${price}&qty=${qty}`;
                } else {
                    alert('Please select at least one ticket.');
                }
            });
        }
    }

    // Instructions Modal Logic
    const instructionsModal = document.getElementById('instructions-modal');
    if (instructionsModal) {
        const howItWorksBtn = document.getElementById('how-it-works-btn');
        const closeBtn = document.getElementById('close-instructions');
        const closeCta = document.getElementById('close-instructions-cta');

        if (howItWorksBtn) {
            howItWorksBtn.addEventListener('click', () => {
                instructionsModal.style.display = 'flex';
            });
        }

        [closeBtn, closeCta].forEach(btn => {
            if (btn) btn.addEventListener('click', () => {
                instructionsModal.style.display = 'none';
            });
        });
    }

    // Modal Global Close
    window.addEventListener('click', (e) => {
        if (e.target.classList.contains('modal-overlay')) {
            e.target.style.display = 'none';
        }
    });
});

// Centralized UI functions
function initCommonUI() {
    const isLoggedIn = localStorage.getItem('isLoggedIn') === 'true';
    const isAuthPage = window.location.pathname.includes('register.html');

    // Auth Guard
    if (!isLoggedIn && !isAuthPage) {
        window.location.href = 'register.html';
        return;
    }

    // Verify Session with Server (handles cases where user was deleted elsewhere)
    if (isLoggedIn) {
        const currentEmail = localStorage.getItem('currentUserEmail');
        const users = JSON.parse(localStorage.getItem('eventlive_users') || '[]');
        if (!users.find(u => u.email === currentEmail)) {
            console.warn("Session invalid: User no longer exists. Logging out.");
            performLogout();
        }
    }

    // Populate User Info and Handle Dropdown
    const userName = localStorage.getItem('userName') || 'User';
    const displayNameEl = document.getElementById('user-display-name');
    const dropdownNameEl = document.getElementById('dropdown-user-name');
    const avatarImg = document.getElementById('avatar-img');

    const userEmail = localStorage.getItem('currentUserEmail') || '';
    const dropdownEmailEl = document.querySelector('.dropdown-user-email');

    if (displayNameEl) displayNameEl.innerText = userName;
    if (dropdownNameEl) dropdownNameEl.innerText = userName;
    if (dropdownEmailEl && userEmail) dropdownEmailEl.innerText = userEmail;

    if (avatarImg) {
        avatarImg.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(userName)}&background=A855F7&color=fff&bold=true&length=1`;
    }

    // Profile Dropdown Logic
    const profileTrigger = document.getElementById('profile-trigger');
    const profileDropdown = document.getElementById('profile-dropdown');

    if (profileTrigger && profileDropdown) {
        profileTrigger.addEventListener('click', (e) => {
            e.stopPropagation();
            profileDropdown.classList.toggle('active');
            profileTrigger.classList.toggle('active');
        });

        document.addEventListener('click', () => {
            profileDropdown.classList.remove('active');
            profileTrigger.classList.remove('active');
        });
    }

    // Logout and Delete Account
    const logoutBtn = document.getElementById('logout-btn');
    const deleteBtn = document.getElementById('delete-account-btn');

    if (logoutBtn) {
        logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            performLogout();
        });
    }

    if (deleteBtn) {
        console.log("Delete button found and listener attached");
        deleteBtn.addEventListener('click', async (e) => {
            e.preventDefault();
            e.stopPropagation(); // Prevent dropdown from closing immediately if needed

            console.log("Delete button clicked");
            if (confirm("Are you sure you want to delete your account permanently? This action cannot be undone.")) {
                const currentEmail = localStorage.getItem('currentUserEmail');
                console.log("Attempting to delete account for:", currentEmail);

                let users = JSON.parse(localStorage.getItem('eventlive_users') || '[]');
                const initialLength = users.length;
                users = users.filter(u => u.email !== currentEmail);

                if (users.length < initialLength) {
                    localStorage.setItem('eventlive_users', JSON.stringify(users));
                    alert("Account deleted successfully.");
                    performLogout();
                } else {
                    alert("Account not found. It may have already been deleted.");
                    performLogout();
                }
            }
        });
    } else {
        console.warn("Delete button not found in the DOM");
    }
}

function performLogout() {
    localStorage.removeItem('isLoggedIn');
    localStorage.removeItem('userName');
    localStorage.removeItem('currentUserEmail');
    window.location.href = 'register.html';
}

