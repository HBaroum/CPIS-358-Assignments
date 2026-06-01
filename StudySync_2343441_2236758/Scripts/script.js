/* ========================================
   Dark Mode Toggle
   ======================================== */

function initDarkMode() {
    var saved = localStorage.getItem("studysync-dark-mode");
    if (saved === "true") {
        document.body.classList.add("dark-mode");
    }
    updateDarkToggleLabel();
}

function toggleDarkMode() {
    document.body.classList.toggle("dark-mode");
    var isDark = document.body.classList.contains("dark-mode");
    localStorage.setItem("studysync-dark-mode", isDark ? "true" : "false");
    updateDarkToggleLabel();
}

function updateDarkToggleLabel() {
    var btn = document.getElementById("darkToggleBtn");
    if (!btn) return;
    var isDark = document.body.classList.contains("dark-mode");
    btn.textContent = isDark ? "Light Mode" : "Dark Mode";
}

document.addEventListener("DOMContentLoaded", function () {
    initDarkMode();
    initSlider();
    initAccordion();
});


/* ========================================
   Password Strength Meter
   ======================================== */

function checkPasswordStrength(value) {
    var fill  = document.getElementById("pwStrengthFill");
    var label = document.getElementById("pwStrengthLabel");
    if (!fill || !label) return;

    var strength = 0;
    if (value.length >= 6)           strength++;
    if (value.length >= 10)          strength++;
    if (/[A-Z]/.test(value))         strength++;
    if (/[0-9]/.test(value))         strength++;
    if (/[^A-Za-z0-9]/.test(value))  strength++;

    var configs = [
        { pct: "0%",   color: "#e0e0e0", text: "",            textColor: "#999"    },
        { pct: "25%",  color: "#e74c3c", text: "Weak",        textColor: "#e74c3c" },
        { pct: "50%",  color: "#e67e22", text: "Fair",        textColor: "#e67e22" },
        { pct: "75%",  color: "#f1c40f", text: "Good",        textColor: "#d4ac0d" },
        { pct: "90%",  color: "#2ecc71", text: "Strong",      textColor: "#27ae60" },
        { pct: "100%", color: "#1abc9c", text: "Very Strong", textColor: "#17a589" }
    ];

    var cfg = configs[strength] || configs[0];
    fill.style.width           = value.length === 0 ? "0%" : cfg.pct;
    fill.style.backgroundColor = cfg.color;
    label.textContent          = cfg.text;
    label.style.color          = cfg.textColor;
}


/* ========================================
   Login Client Validation
   ======================================== */

function validateLoginClient() {
    var result = document.getElementById("clientValidationResult");
    if (result) result.innerHTML = "";

    // Trigger ASP.NET validators so inline error messages appear
    if (typeof Page_ClientValidate === "function" && !Page_ClientValidate()) {
        return false;
    }

    var email    = document.querySelector(".login-email");
    var password = document.querySelector(".login-password");

    if (!email || !password) return true;

    var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailPattern.test(email.value.trim())) {
        if (result) result.innerHTML = "Please enter a valid email address.";
        return false;
    }

    if (result) result.innerHTML = "";
    return true;
}


/* ========================================
   Signup Client Validation
   ======================================== */

function validateSignupClient() {
    var result = document.getElementById("clientValidationResult");
    if (result) result.innerHTML = "";

    // Trigger ASP.NET validators so their inline error messages appear
    if (typeof Page_ClientValidate === "function" && !Page_ClientValidate()) {
        return false;
    }

    var password        = document.querySelector(".password-field");
    var confirmPassword = document.querySelector(".confirm-password-field");

    if (!password || !confirmPassword) return true;

    if (password.value.trim().length < 5) {
        if (result) result.innerHTML = "Password must be at least 5 characters.";
        return false;
    }

    if (password.value !== confirmPassword.value) {
        if (result) result.innerHTML = "Passwords do not match!";
        return false;
    }

    return true;
}




/* ========================================
   Forgot Password Client Validation
   ======================================== */

function validateResetPasswordClient() {
    var result = document.getElementById("clientValidationResult");
    if (result) result.innerHTML = "";

    // Trigger ASP.NET validators so inline error messages appear
    if (typeof Page_ClientValidate === "function" && !Page_ClientValidate()) {
        return false;
    }

    var email           = document.querySelector(".reset-email");
    var studentId       = document.querySelector(".reset-student-id");
    var password        = document.querySelector(".reset-new-password");
    var confirmPassword = document.querySelector(".reset-confirm-password");

    if (!email || !studentId || !password || !confirmPassword) return true;

    var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailPattern.test(email.value.trim())) {
        if (result) result.innerHTML = "Please enter a valid email address.";
        return false;
    }

    if (password.value.trim().length < 5) {
        if (result) result.innerHTML = "Password must be at least 5 characters.";
        return false;
    }

    if (password.value !== confirmPassword.value) {
        if (result) result.innerHTML = "Passwords do not match!";
        return false;
    }

    if (result) result.innerHTML = "";
    return true;
}


/* ========================================
   Home – Dynamic Picture & Text
   ======================================== */

function changeDynamicPictureAndText() {
    var image = document.getElementById("dynamicImage");
    var text  = document.getElementById("dynamicText");

    if (image && text) {
        if (image.getAttribute("src").indexOf("photo2") !== -1) {
            image.setAttribute("src", "Images/photo1.jpg");
            text.innerHTML = "Picture changed dynamically using a JavaScript event!";
        } else {
            image.setAttribute("src", "Images/photo2.jpg");
            text.innerHTML = "This text and image can change using JavaScript.";
        }
    }
}


/* ========================================
   Home – Hero Content Changer (was dead code – now wired)
   ======================================== */

function changeHeroContent() {
    var title = document.getElementById("heroTitle");
    var text  = document.getElementById("heroText");
    var btn   = document.getElementById("btnChangeHero");

    if (!title || !text) return;

    if (title.innerHTML === "Find Your Perfect Study Partner") {
        title.innerHTML = "Plan Better Study Sessions";
        text.innerHTML  = "Use StudySync to organize your time and meet the right partner.";
        if (btn) btn.textContent = "Reset Hero";
    } else {
        title.innerHTML = "Find Your Perfect Study Partner";
        text.innerHTML  = "Same course. Same goal. Same time.";
        if (btn) btn.textContent = "Change Hero Text";
    }
}


/* ========================================
   Home – Study Tips List (was dead code – now wired)
   ======================================== */

var tipCounter = 0;
var extraTips  = [
    "Review your notes after each study session.",
    "Use the Pomodoro technique: 25 min study, 5 min break.",
    "Teach what you learned to your study partner.",
    "Set a specific goal for every session.",
    "Stay off social media during your study block."
];

function addStudyTip() {
    var list = document.getElementById("tipList");
    if (!list) return;

    if (tipCounter >= extraTips.length) {
        tipCounter = 0;
    }

    var newTip        = document.createElement("li");
    newTip.innerHTML  = extraTips[tipCounter];
    newTip.style.animation = "fadeIn 0.4s ease";
    list.appendChild(newTip);
    tipCounter++;
}


/* ========================================
   Image Slider
   ======================================== */

var sliderIndex   = 0;
var sliderTimer   = null;

function initSlider() {
    var slides = document.querySelectorAll(".slide");
    if (slides.length === 0) return;
    showSlide(0);
    sliderTimer = setInterval(function () { moveSlide(1); }, 4000);
}

function showSlide(n) {
    var slides = document.querySelectorAll(".slide");
    var dots   = document.querySelectorAll(".slider-dot");
    if (slides.length === 0) return;

    sliderIndex = (n + slides.length) % slides.length;

    slides.forEach(function (s) { s.classList.remove("active"); });
    dots.forEach(function (d)   { d.classList.remove("active"); });

    slides[sliderIndex].classList.add("active");
    if (dots[sliderIndex]) dots[sliderIndex].classList.add("active");
}

function moveSlide(direction) {
    showSlide(sliderIndex + direction);
}

function goToSlide(n) {
    clearInterval(sliderTimer);
    showSlide(n);
    sliderTimer = setInterval(function () { moveSlide(1); }, 4000);
}


/* ========================================
   Accordion (FAQ)
   ======================================== */

function initAccordion() {
    var headers = document.querySelectorAll(".accordion-header");
    headers.forEach(function (header) {
        header.addEventListener("click", function () {
            var item    = this.parentElement;
            var body    = item.querySelector(".accordion-body");
            var isOpen  = item.classList.contains("open");

            // Close all
            document.querySelectorAll(".accordion-item").forEach(function (i) {
                i.classList.remove("open");
                var b = i.querySelector(".accordion-body");
                if (b) b.style.maxHeight = null;
            });

            // Open clicked if it was closed
            if (!isOpen) {
                item.classList.add("open");
                body.style.maxHeight = body.scrollHeight + "px";
            }
        });
    });
}


/* ========================================
   Home – Welcome Alert (showWelcome)
   ======================================== */

function showWelcome() {
    var box = document.getElementById("welcomeAlertBox");
    if (box) {
        box.style.display = "block";
        setTimeout(function () {
            box.style.opacity = "0";
            box.style.transition = "opacity 0.8s ease";
            setTimeout(function () {
                box.style.display = "none";
                box.style.opacity = "1";
                box.style.transition = "";
            }, 800);
        }, 3000);
    }
}
