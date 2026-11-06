
/* =====================================================
   CareerLaunch - validation.js
   Phase 3: Registration, Login and Client-Side Validation
===================================================== */


/* ---------- PASSWORD VISIBILITY ---------- */

function togglePassword() {
    const passwordField = document.getElementById("password");

    if (!passwordField) {
        return;
    }

    passwordField.type =
        passwordField.type === "password" ? "text" : "password";
}


/* ---------- HELPER: SHOW VALIDATION ERROR ---------- */

function showError(elementId, message) {
    const element = document.getElementById(elementId);

    if (element) {
        element.textContent = message;
    }
}


/* ---------- HELPER: CLEAR VALIDATION ERRORS ---------- */

function clearErrors(errorIds) {
    errorIds.forEach(function (id) {
        showError(id, "");
    });
}


/* ---------- HELPER: GET REGISTERED USERS ---------- */

function getRegisteredUsers() {
    try {
        const savedUsers = localStorage.getItem("careerLaunchUsers");

        if (savedUsers) {
            const users = JSON.parse(savedUsers);

            if (Array.isArray(users)) {
                return users;
            }
        }

        // Migrate the previous version's single registered account.
        const oldUser = localStorage.getItem("careerLaunchUser");

        if (oldUser) {
            const parsedUser = JSON.parse(oldUser);

            if (parsedUser && parsedUser.username) {
                const users = [parsedUser];

                localStorage.setItem(
                    "careerLaunchUsers",
                    JSON.stringify(users)
                );

                return users;
            }
        }
    } catch (error) {
        console.error("Unable to read registered accounts:", error);
    }

    return [];
}


/* ---------- REGISTRATION ---------- */

const registerForm = document.getElementById("registerForm");

if (registerForm) {
    registerForm.addEventListener("submit", function (event) {

        const fullName =
            document.getElementById("fullName").value.trim();

        const username =
            document.getElementById("registerUsername").value.trim();

        const email =
            document.getElementById("registerEmail").value.trim();

        const phone =
            document.getElementById("phone").value.trim();

        const course =
            document.getElementById("course").value;

        const interestElement =
            document.getElementById("interest");

        const interest = interestElement
            ? interestElement.value
            : "";

        const password =
            document.getElementById("registerPassword").value;

        const confirmPassword =
            document.getElementById("confirmPassword").value;

        const terms =
            document.getElementById("terms").checked;

        const errorIds = [
            "fullNameError",
            "registerUsernameError",
            "emailError",
            "phoneError",
            "courseError",
            "registerPasswordError",
            "confirmPasswordError",
            "termsError"
        ];

        clearErrors(errorIds);

        let isValid = true;

        // Validate full name
        if (!fullName) {
            showError(
                "fullNameError",
                "Please enter your full name."
            );

            isValid = false;
        }

        // Validate username
        if (!username) {
            showError(
                "registerUsernameError",
                "Please enter a username."
            );

            isValid = false;
        } else if (/\s/.test(username)) {
            showError(
                "registerUsernameError",
                "Username must not contain spaces."
            );

            isValid = false;
        }

        // Validate email
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!email) {
            showError(
                "emailError",
                "Please enter your email address."
            );

            isValid = false;
        } else if (!emailPattern.test(email)) {
            showError(
                "emailError",
                "Please enter a valid email address."
            );

            isValid = false;
        }

        // Validate phone number
        if (!/^\d{10}$/.test(phone)) {
            showError(
                "phoneError",
                "Enter a valid 10-digit phone number."
            );

            isValid = false;
        }

        // Validate course
        if (!course) {
            showError(
                "courseError",
                "Please select your course."
            );

            isValid = false;
        }

        // Validate password
        if (password.length < 6) {
            showError(
                "registerPasswordError",
                "Password must contain at least 6 characters."
            );

            isValid = false;
        }

        // Validate confirmation
        if (password !== confirmPassword) {
            showError(
                "confirmPasswordError",
                "Passwords do not match."
            );

            isValid = false;
        }

        // Validate terms and conditions
        if (!terms) {
            showError(
                "termsError",
                "Please accept the terms and conditions."
            );

            isValid = false;
        }

        // If client-side validation fails, stop form submission to the Servlet
        if (!isValid) {
            event.preventDefault();
            return;
        }

        // When validation passes:
        // Do NOT preventDefault! Let the form naturally submit via HTTP POST to RegisterServlet.
        // Also keep demonstration profile metadata in localStorage (passwords excluded).
        try {
            const users = getRegisteredUsers();
            const demoAccount = {
                fullName: fullName,
                username: username,
                email: email,
                phone: phone,
                course: course,
                internshipInterest: interest
            };
            users.push(demoAccount);
            localStorage.setItem("careerLaunchUsers", JSON.stringify(users));
        } catch (e) {
            // Local storage error ignored
        }
    });
}



/* ---------- LOGIN ---------- */

const loginForm = document.getElementById("loginForm");

if (loginForm) {
    loginForm.addEventListener("submit", function (event) {

        // Prevent repeated submissions from double-clicking.
        if (loginForm.dataset.submitting === "true") {
            event.preventDefault();
            return;
        }

        const usernameElement =
            document.getElementById("username");

        const passwordElement =
            document.getElementById("password");

        if (!usernameElement || !passwordElement) {
            event.preventDefault();
            alert("Login form fields could not be found.");
            return;
        }

        const username = usernameElement.value.trim();
        const password = passwordElement.value;

        clearErrors(["usernameError", "passwordError"]);

        let isValid = true;

        if (!username) {
            showError(
                "usernameError",
                "Please enter your username or email."
            );
            isValid = false;
        }

        if (!password) {
            showError(
                "passwordError",
                "Please enter your password."
            );
            isValid = false;
        }

        if (!isValid) {
            event.preventDefault();
            return;
        }

        // Do not set any logged-in status in localStorage.
        // Only LoginServlet can authenticate the user on the server.
        loginForm.dataset.submitting = "true";

        const submitButton = loginForm.querySelector(
            'button[type="submit"], input[type="submit"]'
        );

        if (submitButton) {
            submitButton.disabled = true;

            // Safety timeout: re-enable after 3.5 seconds if redirect takes time
            setTimeout(function () {
                submitButton.disabled = false;
                loginForm.dataset.submitting = "false";
            }, 3500);
        }
    });
}

/* ---------- DISPLAY LOGGED-IN USER ---------- */

function displayDashboardUser() {
    const loggedIn =
        localStorage.getItem("careerLaunchLoggedIn");

    const currentUsername =
        localStorage.getItem("careerLaunchCurrentUser");

    if (loggedIn !== "true" || !currentUsername) {
        return;
    }

    const users = getRegisteredUsers();

    const currentUser = users.find(function (user) {
        return (
            user.username.toLowerCase() ===
            currentUsername.toLowerCase()
        );
    });

    if (!currentUser) {
        return;
    }

    const fullName = currentUser.fullName || currentUser.username;
    const firstName = fullName.trim().split(/\s+/)[0];
    const initial = fullName.trim().charAt(0).toUpperCase();

    // Dashboard greeting
    showText("welcomeName", firstName);

    // Top profile
    showText("topbarName", fullName);
    showText("topbarAvatar", initial);

    // Profile information
    showText("profileName", fullName);
    showText("profileEmail", currentUser.email || "No email available");
    showText("profileUsername", currentUser.username || "—");
    showText("profileCourse", currentUser.course || "—");
    showText("profilePhone", currentUser.phone || "—");
    showText("profileAvatar", initial);
}


/* ---------- HELPER: UPDATE TEXT ---------- */

function showText(elementId, value) {
    const element = document.getElementById(elementId);

    if (element) {
        element.textContent = value;
    }
}


/* ---------- LOGOUT ---------- */

function logoutUser() {
    try {
        localStorage.removeItem("careerLaunchLoggedIn");
        localStorage.removeItem("careerLaunchCurrentUser");
    } catch (e) {
        // Ignored
    }

    // Always invalidate the server-side session via LogoutServlet
    window.location.href = "LogoutServlet";
}


/* ---------- PROTECT DASHBOARD ---------- */

const isDashboardPage =
    window.location.pathname.endsWith("dashboard.html");

if (isDashboardPage) {
    // Phase 4: Route all dashboard requests to dashboard.jsp to enforce server-side session authentication
    window.location.replace("dashboard.jsp");
}

async function loadSampleUsersFromJSON() {
    try {
        const response = await fetch("data/user.json");

        if (!response.ok) {
            throw new Error("Unable to load user.json");
        }

        const data = await response.json();

        console.log("Sample users loaded from JSON:", data.users);
    } catch (error) {
        console.error("Error loading JSON data:", error);
    }
}

loadSampleUsersFromJSON();

/* ---------- URL FEEDBACK & SERVER MESSAGES ---------- */
function displayUrlMessages() {
    // Clear any stale localStorage authentication flags when visiting the login page
    if (window.location.pathname.endsWith("login.html") || window.location.pathname.endsWith("/login.html")) {
        try {
            localStorage.removeItem("careerLaunchLoggedIn");
            localStorage.removeItem("careerLaunchCurrentUser");
        } catch (e) {
            // Ignored
        }
    }

    const params = new URLSearchParams(window.location.search);
    const error = params.get("error");
    const msg = params.get("msg");
    const registered = params.get("registered");
    const loggedout = params.get("loggedout");

    // Registration page server error banner
    const serverError = document.getElementById("serverErrorMessage");
    if (serverError && error) {
        serverError.textContent = error;
        serverError.style.display = "block";
    }

    // Login page server notifications
    const serverSuccess = document.getElementById("serverSuccessMessage");
    if (serverSuccess && (registered === "true" || msg)) {
        serverSuccess.textContent = msg || "Registration successful! Please sign in with your credentials.";
        serverSuccess.style.display = "block";
    }

    const serverLogout = document.getElementById("serverLogoutMessage");
    if (serverLogout && loggedout === "true") {
        serverLogout.textContent = msg || "You have been logged out successfully.";
        serverLogout.style.display = "block";
    }

    const loginError = document.getElementById("serverErrorMessage");
    if (loginError && error) {
        loginError.textContent = error;
        loginError.style.display = "block";
    }
}

displayUrlMessages();
