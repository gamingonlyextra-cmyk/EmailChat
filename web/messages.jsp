<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
Integer roleId = (Integer) session.getAttribute("role_id");
Integer userId = (Integer) session.getAttribute("user_id");
String fullName = (String) session.getAttribute("fullName");

if(roleId == null || roleId != 1){
    response.sendRedirect("login.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>TIP SC – Messages</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet" />
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --black: #000;
            --white: #fff;
            --topbar: #e5e5e5;
            --active-tab: #555;
            --light-gray: #f5f5f5;
            --border-gray: #ddd;
        }

        body {
            font-family: 'Inter', sans-serif;
            background: var(--white);
            min-width: 1440px;
            display: flex;
            flex-direction: column;
            height: 100vh;
        }

        /* ── Topbar ── */
        .topbar {
            background: var(--topbar);
            height: 80px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 21px;
            border-bottom: 1px solid var(--border-gray);
        }
        .topbar-left { display: flex; align-items: center; gap: 0; height: 100%; }
        .logo { display: flex; align-items: center; }
        .logo img { width: 48px; height: 48px; }
        .logo-brand { font-size: 32px; font-weight: 600; color: var(--black); letter-spacing: -0.32px; margin-right: 20px; }
        .nav-tab {
            height: 100%;
            display: flex;
            align-items: center;
            padding: 0 11px;
            font-size: 25px;
            font-weight: 600;
            color: var(--black);
            cursor: pointer;
            letter-spacing: -0.25px;
        }
        .nav-tab.active { background: var(--active-tab); color: var(--white); }
        .nav-tab:hover { background: #ddd; }
        .topbar-account { display: flex; align-items: center; gap: 8px; }
        .topbar-account img { width: 48px; height: 48px; }
        .topbar-account span { font-size: 32px; font-weight: 600; letter-spacing: -0.32px; }

        /* ── Main Container ── */
        .messages-container {
            display: flex;
            flex: 1;
            overflow: hidden;
        }

        /* ── Sidebar ── */
        .sidebar {
            width: 300px;
            border-right: 1px solid var(--border-gray);
            display: flex;
            flex-direction: column;
            background: var(--light-gray);
        }
        .sidebar-header {
            padding: 20px;
            border-bottom: 1px solid var(--border-gray);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .sidebar-title {
            font-size: 20px;
            font-weight: 600;
            letter-spacing: -0.2px;
        }
        .new-msg-btn {
            background: var(--black);
            color: var(--white);
            border: none;
            border-radius: 4px;
            padding: 6px 12px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
        }
        .new-msg-btn:hover { background: #333; }

        .conversations-list {
            flex: 1;
            overflow-y: auto;
            list-style: none;
        }
        .conversation-item {
            padding: 15px;
            border-bottom: 1px solid var(--border-gray);
            cursor: pointer;
            transition: background 0.2s;
        }
        .conversation-item:hover { background: #e8e8e8; }
        .conversation-item.active { background: var(--white); border-left: 4px solid var(--black); padding-left: 11px; }
        .conversation-name {
            font-size: 16px;
            font-weight: 600;
            letter-spacing: -0.16px;
            color: var(--black);
        }
        .conversation-preview {
            font-size: 13px;
            color: #666;
            margin-top: 4px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .conversation-time {
            font-size: 12px;
            color: #999;
            margin-top: 4px;
        }

        .empty-state {
            padding: 40px 20px;
            text-align: center;
            color: #999;
        }
        .empty-state-title {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 10px;
            color: var(--black);
        }
        .empty-state-text {
            font-size: 14px;
            margin-bottom: 15px;
        }

        /* ── Chat Area ── */
        .chat-area {
            flex: 1;
            display: flex;
            flex-direction: column;
            background: var(--white);
        }

        .chat-header {
            padding: 20px;
            border-bottom: 1px solid var(--border-gray);
            background: var(--light-gray);
        }
        .chat-header-name {
            font-size: 20px;
            font-weight: 600;
            letter-spacing: -0.2px;
        }
        .chat-header-email {
            font-size: 14px;
            color: #666;
            margin-top: 2px;
        }

        .messages-box {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 15px;
        }

        .message {
            display: flex;
            margin-bottom: 10px;
        }
        .message.sent {
            justify-content: flex-end;
        }
        .message.received {
            justify-content: flex-start;
        }

        .message-bubble {
            max-width: 60%;
            padding: 12px 16px;
            border-radius: 12px;
            word-wrap: break-word;
            word-break: break-word;
        }
        .message.sent .message-bubble {
            background: var(--black);
            color: var(--white);
        }
        .message.received .message-bubble {
            background: var(--light-gray);
            color: var(--black);
        }

        .message-time {
            font-size: 12px;
            color: #999;
            margin-top: 4px;
            text-align: right;
        }
        .message.received .message-time {
            text-align: left;
        }

        .chat-input-area {
            padding: 20px;
            border-top: 1px solid var(--border-gray);
            background: var(--white);
            display: flex;
            gap: 10px;
        }
        .chat-input {
            flex: 1;
            border: 1px solid var(--border-gray);
            border-radius: 8px;
            padding: 12px;
            font-family: 'Inter', sans-serif;
            font-size: 16px;
            resize: none;
            height: 45px;
            outline: none;
        }
        .chat-input:focus { outline: 1px solid var(--black); }
        .send-btn {
            background: var(--black);
            color: var(--white);
            border: none;
            border-radius: 8px;
            padding: 0 20px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
        }
        .send-btn:hover { background: #333; }
        .send-btn:disabled { background: #ccc; cursor: not-allowed; }

        /* ── Modal ── */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.4);
        }
        .modal.active { display: block; }
        .modal-content {
            background-color: var(--white);
            margin: 10% auto;
            padding: 30px;
            border: 1px solid var(--border-gray);
            border-radius: 8px;
            width: 400px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .modal-title {
            font-size: 22px;
            font-weight: 600;
            margin-bottom: 20px;
            letter-spacing: -0.22px;
        }
        .modal-input {
            width: 100%;
            padding: 12px;
            border: 1px solid var(--border-gray);
            border-radius: 6px;
            font-family: 'Inter', sans-serif;
            font-size: 16px;
            margin-bottom: 20px;
            outline: none;
        }
        .modal-input:focus { outline: 1px solid var(--black); }
        .modal-error {
            color: #d32f2f;
            font-size: 14px;
            margin-bottom: 15px;
            display: none;
        }
        .modal-error.show { display: block; }
        .modal-buttons {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        .modal-btn {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
        }
        .modal-btn-primary {
            background: var(--black);
            color: var(--white);
        }
        .modal-btn-primary:hover { background: #333; }
        .modal-btn-primary:disabled { background: #ccc; cursor: not-allowed; }
        .modal-btn-secondary {
            background: var(--light-gray);
            color: var(--black);
            border: 1px solid var(--border-gray);
        }
        .modal-btn-secondary:hover { background: #e8e8e8; }

        .select-conversation-placeholder {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            color: #999;
        }
        .select-conversation-placeholder-title {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 10px;
            color: var(--black);
        }
    </style>
</head>
<body>

<!-- Top Bar -->
<header class="topbar">
    <div class="topbar-left">
        <div class="logo">
            <img src="https://www.figma.com/api/mcp/asset/bb6eba5f-daae-4d2c-b20a-3e7943a0549d" alt="logo" />
            <span class="logo-brand">TIP SC</span>
        </div>
        <div class="nav-tab" onclick="window.location.href='student_dashboard.jsp'">My Complaints</div>
        <div class="nav-tab" onclick="window.location.href='submit_complaint.jsp'">Submit Complaint</div>
        <div class="nav-tab active">Message</div>
    </div>
    <div class="topbar-account">
        <img src="https://www.figma.com/api/mcp/asset/92d22bc0-450b-4022-8844-485488d13931" alt="account" />
        <span><%= fullName %></span>
    </div>
</header>

<!-- Main Container -->
<div class="messages-container">
    <!-- Sidebar -->
    <div class="sidebar">
        <div class="sidebar-header">
            <div class="sidebar-title">Messages</div>
            <button class="new-msg-btn" onclick="openNewMessageModal()">+ New</button>
        </div>
        <ul class="conversations-list" id="conversationsList">
            <div class="empty-state">
                <div class="empty-state-title">No Conversations</div>
                <div class="empty-state-text">Start a new message by clicking the + New button</div>
            </div>
        </ul>
    </div>

    <!-- Chat Area -->
    <div class="chat-area">
        <div id="chatContainer" style="display: none; flex: 1; display: flex; flex-direction: column;">
            <div class="chat-header">
                <div class="chat-header-name" id="chatHeaderName">Select a conversation</div>
                <div class="chat-header-email" id="chatHeaderEmail"></div>
            </div>
            <div class="messages-box" id="messagesBox">
                <!-- Messages will be loaded here -->
            </div>
            <div class="chat-input-area">
                <textarea class="chat-input" id="messageInput" placeholder="Type a message..."></textarea>
                <button class="send-btn" id="sendBtn" onclick="sendMessage()">Send</button>
            </div>
        </div>
        <div id="selectConversationPlaceholder" style="flex: 1; display: flex; align-items: center; justify-content: center;">
            <div class="select-conversation-placeholder">
                <div class="select-conversation-placeholder-title">No Conversation Selected</div>
                <p>Select a conversation to start messaging or create a new one</p>
            </div>
        </div>
    </div>
</div>

<!-- New Message Modal -->
<div id="newMessageModal" class="modal">
    <div class="modal-content">
        <div class="modal-title">Start New Chat</div>
        <input type="email" class="modal-input" id="recipientEmail" placeholder="Enter recipient's email address" />
        <div class="modal-error" id="modalError"></div>
        <div class="modal-buttons">
            <button class="modal-btn modal-btn-secondary" onclick="closeNewMessageModal()">Cancel</button>
            <button class="modal-btn modal-btn-primary" id="startChatBtn" onclick="startNewChat()">Start Chat</button>
        </div>
    </div>
</div>

<script>
    let currentConversations = [];
    let currentChatUserId = null;
    let currentConversationId = null;
    let autoRefreshInterval = null;

    const currentUserId = <%= userId %>;

    // Load conversations on page load
    window.addEventListener('load', function() {
        console.log('Page loaded for user: ' + currentUserId);
        loadConversations();
        startAutoRefresh();
    });

    /**
     * Load all conversations for the current user
     */
    function loadConversations() {
        console.log('Loading conversations...');
        const xhr = new XMLHttpRequest();
        xhr.open('GET', 'MessagesServlet?action=getConversations', true);
        xhr.onload = function() {
            console.log('Conversations response status: ' + xhr.status);
            if (xhr.status === 200) {
                try {
                    currentConversations = JSON.parse(xhr.responseText);
                    console.log('Loaded ' + currentConversations.length + ' conversations');
                    displayConversations();
                } catch (e) {
                    console.error('Error parsing conversations:', e);
                    console.log('Response text: ' + xhr.responseText);
                }
            } else {
                console.error('Error loading conversations: ' + xhr.status);
            }
        };
        xhr.onerror = function() {
            console.error('Network error loading conversations');
        };
        xhr.send();
    }

    /**
     * Display conversations in the sidebar
     */
    function displayConversations() {
        const list = document.getElementById('conversationsList');
        list.innerHTML = '';

        if (currentConversations.length === 0) {
            const emptyDiv = document.createElement('div');
            emptyDiv.className = 'empty-state';
            emptyDiv.innerHTML = '<div class="empty-state-title">No Conversations</div><div class="empty-state-text">Start a new message by clicking the + New button</div>';
            list.appendChild(emptyDiv);
            return;
        }

        currentConversations.forEach((conv) => {
            const item = document.createElement('li');
            item.className = 'conversation-item';
            item.id = 'conv-' + conv.otherUserId;
            
            const lastMessageTime = conv.lastMessageAt ? new Date(conv.lastMessageAt).toLocaleDateString() : '';
            const lastMessage = conv.lastMessage ? (conv.lastMessage.length > 50 ? conv.lastMessage.substring(0, 47) + '...' : conv.lastMessage) : 'No messages yet';
            
            const nameDiv = document.createElement('div');
            nameDiv.className = 'conversation-name';
            nameDiv.textContent = conv.fullName;
            
            const previewDiv = document.createElement('div');
            previewDiv.className = 'conversation-preview';
            previewDiv.textContent = lastMessage;
            
            const timeDiv = document.createElement('div');
            timeDiv.className = 'conversation-time';
            timeDiv.textContent = lastMessageTime;
            
            item.appendChild(nameDiv);
            item.appendChild(previewDiv);
            item.appendChild(timeDiv);
            
            item.addEventListener('click', function() {
                openConversation(conv.otherUserId, conv.fullName, conv.email, conv.conversationId);
            });
            
            list.appendChild(item);
        });
    }

    /**
     * Open a conversation and load chat history
     */
    function openConversation(userId, fullName, email, conversationId) {
        currentChatUserId = userId;
        currentConversationId = conversationId;
        
        console.log('Opening conversation with user ' + userId + ' (conversation ID: ' + conversationId + ')');
        
        document.getElementById('selectConversationPlaceholder').style.display = 'none';
        document.getElementById('chatContainer').style.display = 'flex';
        document.getElementById('chatHeaderName').textContent = fullName;
        document.getElementById('chatHeaderEmail').textContent = email;

        loadChatHistory(userId);

        // Mark all items as inactive
        document.querySelectorAll('.conversation-item').forEach(item => {
            item.classList.remove('active');
        });
        
        // Mark current as active
        const currentItem = document.getElementById('conv-' + userId);
        if (currentItem) {
            currentItem.classList.add('active');
        }
    }

    /**
     * Load chat history between current user and another user
     */
    function loadChatHistory(userId) {
        console.log('Loading chat history with user ' + userId);
        const xhr = new XMLHttpRequest();
        xhr.open('GET', 'MessagesServlet?action=getChatHistory&otherUserId=' + userId, true);
        xhr.onload = function() {
            console.log('Chat history response status: ' + xhr.status);
            if (xhr.status === 200) {
                try {
                    const messages = JSON.parse(xhr.responseText);
                    console.log('Loaded ' + messages.length + ' messages');
                    displayChatMessages(messages);
                } catch (e) {
                    console.error('Error parsing messages:', e);
                    console.log('Response text: ' + xhr.responseText);
                }
            } else {
                console.error('Error loading chat history: ' + xhr.status);
            }
        };
        xhr.onerror = function() {
            console.error('Network error loading chat history');
        };
        xhr.send();
    }

    /**
     * Display messages in the chat area
     */
    function displayChatMessages(messages) {
        const messagesBox = document.getElementById('messagesBox');
        messagesBox.innerHTML = '';

        if (messages.length === 0) {
            const emptyDiv = document.createElement('div');
            emptyDiv.style.textAlign = 'center';
            emptyDiv.style.color = '#999';
            emptyDiv.style.marginTop = '20px';
            emptyDiv.textContent = 'No messages yet. Start the conversation!';
            messagesBox.appendChild(emptyDiv);
            return;
        }

        messages.forEach(msg => {
            const msgDiv = document.createElement('div');
            const isSent = msg.senderId === currentUserId;
            msgDiv.className = 'message ' + (isSent ? 'sent' : 'received');

            const date = new Date(msg.sentAt).toLocaleTimeString();

            const bubbleDiv = document.createElement('div');
            const messageBubble = document.createElement('div');
            messageBubble.className = 'message-bubble';
            messageBubble.textContent = msg.messageText;
            
            const timeDiv = document.createElement('div');
            timeDiv.className = 'message-time';
            timeDiv.textContent = date;
            
            bubbleDiv.appendChild(messageBubble);
            bubbleDiv.appendChild(timeDiv);
            msgDiv.appendChild(bubbleDiv);
            messagesBox.appendChild(msgDiv);
        });

        // Scroll to bottom
        messagesBox.scrollTop = messagesBox.scrollHeight;
    }

    /**
     * Send a message in the current conversation
     */
    function sendMessage() {
        const input = document.getElementById('messageInput');
        const messageText = input.value.trim();
        const sendBtn = document.getElementById('sendBtn');

        if (!messageText || !currentChatUserId) {
            alert('Please select a conversation and type a message');
            return;
        }

        sendBtn.disabled = true;
        console.log('Sending message to user ' + currentChatUserId);

        const formData = new FormData();
        formData.append('action', 'sendMessage');
        formData.append('otherUserId', currentChatUserId);
        formData.append('messageText', messageText);

        fetch('MessagesServlet', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            console.log('Send message response:', data);
            if (data.status === 'success') {
                input.value = '';
                loadChatHistory(currentChatUserId);
                loadConversations();
            } else {
                alert('Error: ' + (data.message || 'Failed to send message'));
            }
            sendBtn.disabled = false;
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error: ' + error.message);
            sendBtn.disabled = false;
        });
    }

    /**
     * Open the new message modal
     */
    function openNewMessageModal() {
        document.getElementById('newMessageModal').classList.add('active');
        document.getElementById('modalError').textContent = '';
        document.getElementById('modalError').classList.remove('show');
        document.getElementById('recipientEmail').value = '';
        document.getElementById('recipientEmail').focus();
    }

    /**
     * Close the new message modal
     */
    function closeNewMessageModal() {
        document.getElementById('newMessageModal').classList.remove('active');
    }

    /**
     * Start a new chat with a user by email
     */
    function startNewChat() {
        const email = document.getElementById('recipientEmail').value.trim();
        const errorDiv = document.getElementById('modalError');
        const startChatBtn = document.getElementById('startChatBtn');

        // Validate email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!email || !emailRegex.test(email)) {
            errorDiv.textContent = 'Please enter a valid email address';
            errorDiv.classList.add('show');
            return;
        }

        startChatBtn.disabled = true;
        console.log('Starting new chat with email: ' + email);

        const formData = new FormData();
        formData.append('action', 'startNewChat');
        formData.append('recipientEmail', email);

        fetch('MessagesServlet', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            console.log('Start new chat response:', data);
            if (data.status === 'success') {
                closeNewMessageModal();
                loadConversations();
                // Open the new conversation
                setTimeout(function() {
                    openConversation(data.recipientId, data.recipientName, email, data.conversationId);
                }, 200);
            } else {
                errorDiv.textContent = data.message || 'Error starting chat';
                errorDiv.classList.add('show');
            }
            startChatBtn.disabled = false;
        })
        .catch(error => {
            errorDiv.textContent = 'Error: ' + error.message;
            errorDiv.classList.add('show');
            console.error('Error:', error);
            startChatBtn.disabled = false;
        });
    }

    /**
     * Auto-refresh conversations and chat history
     */
    function startAutoRefresh() {
        autoRefreshInterval = setInterval(function() {
            if (currentChatUserId) {
                loadChatHistory(currentChatUserId);
            }
            loadConversations();
        }, 5000);
    }

    /**
     * Stop auto-refresh when leaving the page
     */
    window.addEventListener('beforeunload', function() {
        if (autoRefreshInterval) {
            clearInterval(autoRefreshInterval);
        }
    });

    /**
     * Allow sending message with Enter key
     */
    document.addEventListener('keypress', function(event) {
        if (event.key === 'Enter' && !event.shiftKey && event.target.id === 'messageInput') {
            event.preventDefault();
            sendMessage();
        }
    });

    /**
     * Close modal when clicking outside of it
     */
    window.onclick = function(event) {
        const modal = document.getElementById('newMessageModal');
        if (event.target === modal) {
            closeNewMessageModal();
        }
    };
</script>

</body>
</html>