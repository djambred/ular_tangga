// API Configuration
const API_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:3000/api' 
    : '/api';

let currentUser = null;
let authToken = null;

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    setupEventListeners();
});

// Check authentication
function checkAuth() {
    authToken = localStorage.getItem('admin_token');
    if (authToken) {
        loadDashboard();
    } else {
        showScreen('loginScreen');
    }
}

// Setup event listeners
function setupEventListeners() {
    // Login form
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    
    // Logout button
    document.getElementById('logoutBtn').addEventListener('click', handleLogout);
    
    // Sidebar navigation
    document.querySelectorAll('.sidebar-menu a[data-page]').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const page = e.target.getAttribute('data-page');
            navigateToPage(page);
        });
    });
    
    // Add quiz button
    document.getElementById('addQuizBtn').addEventListener('click', () => {
        openQuizModal();
    });
    
    // Quiz form
    document.getElementById('quizForm').addEventListener('submit', handleQuizSubmit);
    
    // Modal close buttons
    document.querySelectorAll('.close, .cancel-btn').forEach(btn => {
        btn.addEventListener('click', closeModals);
    });
    
    // Leaderboard tabs
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const sortBy = e.target.getAttribute('data-sort');
            loadLeaderboard(sortBy);
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
        });
    });
    
    // Search and filters
    document.getElementById('searchUsers')?.addEventListener('input', debounce(loadUsers, 500));
    document.getElementById('filterRole')?.addEventListener('change', loadUsers);
    document.getElementById('filterGameMode')?.addEventListener('change', loadGames);
    document.getElementById('filterLevel')?.addEventListener('change', loadGames);
}

// Handle login
async function handleLogin(e) {
    e.preventDefault();
    const username = document.getElementById('loginUsername').value;
    const password = document.getElementById('loginPassword').value;
    const errorDiv = document.getElementById('loginError');
    
    try {
        const response = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        
        const data = await response.json();
        
        if (data.success && data.data.user.role === 'admin') {
            authToken = data.data.token;
            currentUser = data.data.user;
            localStorage.setItem('admin_token', authToken);
            showScreen('dashboardScreen');
            loadDashboard();
        } else {
            errorDiv.textContent = data.message || 'Login failed. Only admin can access.';
            errorDiv.classList.add('show');
        }
    } catch (error) {
        errorDiv.textContent = 'Connection error. Please check server.';
        errorDiv.classList.add('show');
    }
}

// Handle logout
function handleLogout() {
    localStorage.removeItem('admin_token');
    authToken = null;
    currentUser = null;
    showScreen('loginScreen');
}

// Load dashboard data
async function loadDashboard() {
    document.getElementById('adminName').textContent = currentUser?.fullName || 'Admin';
    navigateToPage('overview');
    await loadOverview();
}

// Navigate to page
function navigateToPage(pageName) {
    document.querySelectorAll('.page').forEach(page => page.classList.remove('active'));
    document.querySelectorAll('.sidebar-menu a').forEach(link => link.classList.remove('active'));
    
    document.getElementById(`${pageName}Page`).classList.add('active');
    document.querySelector(`[data-page="${pageName}"]`)?.classList.add('active');
    
    // Load page data
    switch(pageName) {
        case 'overview': loadOverview(); break;
        case 'users': loadUsers(); break;
        case 'quizzes': loadQuizzes(); break;
        case 'games': loadGames(); break;
        case 'leaderboard': loadLeaderboard(); break;
    }
}

// Load overview statistics
async function loadOverview() {
    try {
        const [userStats, gameStats, quizStats] = await Promise.all([
            apiGet('/users/statistics'),
            apiGet('/game/statistics'),
            apiGet('/quiz/statistics')
        ]);
        
        document.getElementById('totalUsers').textContent = userStats.data.total;
        document.getElementById('totalGames').textContent = gameStats.data.total;
        document.getElementById('totalQuizzes').textContent = quizStats.data.total;
        
        const avgMin = Math.floor((gameStats.data.averageDuration || 0) / 60);
        document.getElementById('avgDuration').textContent = `${avgMin}m`;
        
        // Recent games
        renderRecentGames(gameStats.data.recentGames || []);
        
        // Recent users
        renderRecentUsers(userStats.data.recentUsers || []);
    } catch (error) {
        console.error('Load overview error:', error);
    }
}

// Render recent games
function renderRecentGames(games) {
    const container = document.getElementById('recentGames');
    if (games.length === 0) {
        container.innerHTML = '<div class="empty-state">Belum ada game</div>';
        return;
    }
    
    const html = `
        <table>
            <thead>
                <tr>
                    <th>Mode</th>
                    <th>Level</th>
                    <th>Players</th>
                    <th>Duration</th>
                </tr>
            </thead>
            <tbody>
                ${games.map(game => `
                    <tr>
                        <td><span class="badge badge-${game.gameMode === 'single' ? 'info' : 'success'}">${game.gameMode}</span></td>
                        <td>Level ${game.level}</td>
                        <td>${game.players.length}</td>
                        <td>${Math.floor(game.duration / 60)}m ${game.duration % 60}s</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
    container.innerHTML = html;
}

// Render recent users
function renderRecentUsers(users) {
    const container = document.getElementById('recentUsers');
    if (users.length === 0) {
        container.innerHTML = '<div class="empty-state">Belum ada user</div>';
        return;
    }
    
    const html = `
        <table>
            <thead>
                <tr>
                    <th>Username</th>
                    <th>Role</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                ${users.map(user => `
                    <tr>
                        <td>${user.username}</td>
                        <td><span class="badge badge-info">${user.role}</span></td>
                        <td><span class="badge badge-${user.isActive ? 'success' : 'danger'}">${user.isActive ? 'Active' : 'Inactive'}</span></td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
    container.innerHTML = html;
}

// Load users
async function loadUsers(page = 1) {
    try {
        const search = document.getElementById('searchUsers').value;
        const role = document.getElementById('filterRole').value;
        
        let url = `/users?page=${page}&limit=20`;
        if (search) url += `&search=${search}`;
        if (role) url += `&role=${role}`;
        
        const data = await apiGet(url);
        renderUsersTable(data.data);
        renderPagination('usersPagination', data.pagination, loadUsers);
    } catch (error) {
        console.error('Load users error:', error);
    }
}

// Render users table
function renderUsersTable(users) {
    const container = document.getElementById('usersTable');
    if (users.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">👥</div><p>Tidak ada user</p></div>';
        return;
    }
    
    const html = `
        <table>
            <thead>
                <tr>
                    <th>Username</th>
                    <th>Full Name</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th>Games</th>
                    <th>Wins</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${users.map(user => `
                    <tr>
                        <td>${user.username}</td>
                        <td>${user.fullName}</td>
                        <td>${user.email}</td>
                        <td><span class="badge badge-info">${user.role}</span></td>
                        <td>${user.statistics.totalGames}</td>
                        <td>${user.statistics.totalWins}</td>
                        <td><span class="badge badge-${user.isActive ? 'success' : 'danger'}">${user.isActive ? 'Active' : 'Inactive'}</span></td>
                        <td>
                            <button class="btn btn-sm btn-secondary" onclick="toggleUserStatus('${user._id}', ${!user.isActive})">
                                ${user.isActive ? 'Nonaktifkan' : 'Aktifkan'}
                            </button>
                        </td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
    container.innerHTML = html;
}

// Toggle user status
async function toggleUserStatus(userId, isActive) {
    try {
        await apiPut(`/users/${userId}`, { isActive });
        showToast('Status user berhasil diupdate');
        loadUsers();
    } catch (error) {
        showToast('Gagal update status user', 'error');
    }
}

// Load quizzes
async function loadQuizzes() {
    try {
        const data = await apiGet('/quiz');
        renderQuizzesTable(data.data);
    } catch (error) {
        console.error('Load quizzes error:', error);
    }
}

// Render quizzes table
function renderQuizzesTable(quizzes) {
    const container = document.getElementById('quizzesTable');
    if (quizzes.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📝</div><p>Belum ada quiz</p></div>';
        return;
    }
    
    const html = `
        <table>
            <thead>
                <tr>
                    <th>Question</th>
                    <th>Category</th>
                    <th>Difficulty</th>
                    <th>Answered</th>
                    <th>Correct Rate</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${quizzes.map(quiz => {
                    const correctRate = quiz.timesAnswered > 0 ? Math.round((quiz.timesCorrect / quiz.timesAnswered) * 100) : 0;
                    return `
                        <tr>
                            <td style="max-width: 300px;">${quiz.question}</td>
                            <td><span class="badge badge-info">${quiz.category}</span></td>
                            <td><span class="badge badge-warning">${quiz.difficulty}</span></td>
                            <td>${quiz.timesAnswered}</td>
                            <td>${correctRate}%</td>
                            <td><span class="badge badge-${quiz.isActive ? 'success' : 'danger'}">${quiz.isActive ? 'Active' : 'Inactive'}</span></td>
                            <td>
                                <button class="btn btn-sm btn-secondary" onclick='editQuiz(${JSON.stringify(quiz)})'>Edit</button>
                                <button class="btn btn-sm btn-danger" onclick="deleteQuiz('${quiz._id}')">Delete</button>
                            </td>
                        </tr>
                    `;
                }).join('')}
            </tbody>
        </table>
    `;
    container.innerHTML = html;
}

// Open quiz modal
function openQuizModal(quiz = null) {
    const modal = document.getElementById('quizModal');
    const form = document.getElementById('quizForm');
    
    if (quiz) {
        document.getElementById('quizModalTitle').textContent = 'Edit Quiz';
        document.getElementById('quizId').value = quiz._id;
        document.getElementById('quizQuestion').value = quiz.question;
        quiz.options.forEach((opt, i) => {
            document.getElementById(`quizOption${i}`).value = opt;
        });
        document.getElementById('quizCorrectAnswer').value = quiz.correctAnswer;
        document.getElementById('quizExplanation').value = quiz.explanation;
        document.getElementById('quizCategory').value = quiz.category;
        document.getElementById('quizDifficulty').value = quiz.difficulty;
        document.getElementById('quizIsActive').checked = quiz.isActive;
    } else {
        document.getElementById('quizModalTitle').textContent = 'Tambah Quiz';
        form.reset();
        document.getElementById('quizId').value = '';
        document.getElementById('quizIsActive').checked = true;
    }
    
    modal.classList.add('active');
}

function editQuiz(quiz) {
    openQuizModal(quiz);
}

// Handle quiz form submit
async function handleQuizSubmit(e) {
    e.preventDefault();
    
    const quizId = document.getElementById('quizId').value;
    const quizData = {
        question: document.getElementById('quizQuestion').value,
        options: [
            document.getElementById('quizOption0').value,
            document.getElementById('quizOption1').value,
            document.getElementById('quizOption2').value,
            document.getElementById('quizOption3').value
        ],
        correctAnswer: parseInt(document.getElementById('quizCorrectAnswer').value),
        explanation: document.getElementById('quizExplanation').value,
        category: document.getElementById('quizCategory').value,
        difficulty: document.getElementById('quizDifficulty').value,
        isActive: document.getElementById('quizIsActive').checked
    };
    
    try {
        if (quizId) {
            await apiPut(`/quiz/${quizId}`, quizData);
            showToast('Quiz berhasil diupdate');
        } else {
            await apiPost('/quiz', quizData);
            showToast('Quiz berhasil ditambahkan');
        }
        closeModals();
        loadQuizzes();
    } catch (error) {
        showToast('Gagal menyimpan quiz', 'error');
    }
}

// Delete quiz
async function deleteQuiz(quizId) {
    if (!confirm('Yakin ingin menghapus quiz ini?')) return;
    
    try {
        await apiDelete(`/quiz/${quizId}`);
        showToast('Quiz berhasil dihapus');
        loadQuizzes();
    } catch (error) {
        showToast('Gagal menghapus quiz', 'error');
    }
}

// Load games
async function loadGames(page = 1) {
    try {
        const gameMode = document.getElementById('filterGameMode').value;
        const level = document.getElementById('filterLevel').value;
        
        let url = `/game/history/all?page=${page}&limit=20`;
        if (gameMode) url += `&gameMode=${gameMode}`;
        if (level) url += `&level=${level}`;
        
        const data = await apiGet(url);
        renderGamesTable(data.data);
        renderPagination('gamesPagination', data.pagination, loadGames);
    } catch (error) {
        console.error('Load games error:', error);
    }
}

// Render games table
function renderGamesTable(games) {
    const container = document.getElementById('gamesTable');
    if (games.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🎮</div><p>Belum ada game</p></div>';
        return;
    }
    
    const html = `
        <table>
            <thead>
                <tr>
                    <th>Game ID</th>
                    <th>Mode</th>
                    <th>Level</th>
                    <th>Players</th>
                    <th>Winner</th>
                    <th>Duration</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                ${games.map(game => {
                    const winner = game.players.find(p => p.isWinner);
                    return `
                        <tr>
                            <td>${game.gameId.substring(0, 8)}...</td>
                            <td><span class="badge badge-${game.gameMode === 'single' ? 'info' : 'success'}">${game.gameMode}</span></td>
                            <td>Level ${game.level}</td>
                            <td>${game.players.length}</td>
                            <td>${winner ? winner.username : 'N/A'}</td>
                            <td>${Math.floor(game.duration / 60)}m ${game.duration % 60}s</td>
                            <td>${new Date(game.createdAt).toLocaleDateString()}</td>
                        </tr>
                    `;
                }).join('')}
            </tbody>
        </table>
    `;
    container.innerHTML = html;
}

// Load leaderboard
async function loadLeaderboard(sortBy = 'wins') {
    try {
        const data = await apiGet(`/game/leaderboard?sortBy=${sortBy}&limit=20`);
        renderLeaderboardTable(data, sortBy);
    } catch (error) {
        console.error('Load leaderboard error:', error);
    }
}

// Render leaderboard table
function renderLeaderboardTable(players, sortBy) {
    const container = document.getElementById('leaderboardTable');
    if (players.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🏆</div><p>Belum ada data</p></div>';
        return;
    }
    
    const getStatValue = (player) => {
        switch(sortBy) {
            case 'wins': return player.statistics.totalWins;
            case 'games': return player.statistics.totalGames;
            case 'quizzes': return player.statistics.totalQuizzesCorrect;
            default: return player.statistics.totalWins;
        }
    };
    
    const html = `
        <table>
            <thead>
                <tr>
                    <th>Rank</th>
                    <th>Username</th>
                    <th>Full Name</th>
                    <th>Total Games</th>
                    <th>Wins</th>
                    <th>Win Rate</th>
                    <th>Quizzes Correct</th>
                </tr>
            </thead>
            <tbody>
                ${players.map((player, index) => {
                    const winRate = player.statistics.totalGames > 0 
                        ? Math.round((player.statistics.totalWins / player.statistics.totalGames) * 100) 
                        : 0;
                    return `
                        <tr>
                            <td><strong>${index + 1}</strong></td>
                            <td>${player.username}</td>
                            <td>${player.fullName}</td>
                            <td>${player.statistics.totalGames}</td>
                            <td>${player.statistics.totalWins}</td>
                            <td>${winRate}%</td>
                            <td>${player.statistics.totalQuizzesCorrect}</td>
                        </tr>
                    `;
                }).join('')}
            </tbody>
        </table>
    `;
    container.innerHTML = html;
}

// Render pagination
function renderPagination(containerId, pagination, loadFunction) {
    const container = document.getElementById(containerId);
    if (!pagination || pagination.pages <= 1) {
        container.innerHTML = '';
        return;
    }
    
    let html = '';
    html += `<button onclick="${loadFunction.name}(${pagination.page - 1})" ${pagination.page === 1 ? 'disabled' : ''}>Previous</button>`;
    
    for (let i = 1; i <= pagination.pages; i++) {
        if (i === 1 || i === pagination.pages || (i >= pagination.page - 2 && i <= pagination.page + 2)) {
            html += `<button onclick="${loadFunction.name}(${i})" ${i === pagination.page ? 'class="active"' : ''}>${i}</button>`;
        } else if (i === pagination.page - 3 || i === pagination.page + 3) {
            html += '<span>...</span>';
        }
    }
    
    html += `<button onclick="${loadFunction.name}(${pagination.page + 1})" ${pagination.page === pagination.pages ? 'disabled' : ''}>Next</button>`;
    container.innerHTML = html;
}

// API Helper functions
async function apiGet(endpoint) {
    const response = await fetch(`${API_URL}${endpoint}`, {
        headers: { 'Authorization': `Bearer ${authToken}` }
    });
    const data = await response.json();
    if (!data.success) throw new Error(data.message);
    return data;
}

async function apiPost(endpoint, body) {
    const response = await fetch(`${API_URL}${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify(body)
    });
    const data = await response.json();
    if (!data.success) throw new Error(data.message);
    return data;
}

async function apiPut(endpoint, body) {
    const response = await fetch(`${API_URL}${endpoint}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify(body)
    });
    const data = await response.json();
    if (!data.success) throw new Error(data.message);
    return data;
}

async function apiDelete(endpoint) {
    const response = await fetch(`${API_URL}${endpoint}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${authToken}` }
    });
    const data = await response.json();
    if (!data.success) throw new Error(data.message);
    return data;
}

// Utility functions
function showScreen(screenId) {
    document.querySelectorAll('.screen').forEach(screen => screen.classList.remove('active'));
    document.getElementById(screenId).classList.add('active');
}

function closeModals() {
    document.querySelectorAll('.modal').forEach(modal => modal.classList.remove('active'));
}

function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `${type}-message`;
    toast.textContent = message;
    toast.style.position = 'fixed';
    toast.style.top = '20px';
    toast.style.right = '20px';
    toast.style.zIndex = '9999';
    toast.style.padding = '15px 20px';
    toast.style.borderRadius = '10px';
    toast.style.boxShadow = '0 5px 20px rgba(0,0,0,0.2)';
    document.body.appendChild(toast);
    
    setTimeout(() => toast.remove(), 3000);
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Make functions available globally
window.editQuiz = editQuiz;
window.deleteQuiz = deleteQuiz;
window.toggleUserStatus = toggleUserStatus;
window.loadUsers = loadUsers;
window.loadGames = loadGames;
