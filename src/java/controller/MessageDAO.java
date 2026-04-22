package controller;

import java.sql.*;
import java.util.*;

/**
 * Data Access Object for user-to-user messaging
 * Handles CONVERSATIONS and MESSAGES tables
 */
public class MessageDAO {
    
    /**
     * Get all conversations for a user
     */
    public List<Map<String, Object>> getConversations(int userId) {
        List<Map<String, Object>> conversations = new ArrayList<>();
        
        try (Connection conn = util.DBConnection.getConnection()) {
            
            System.out.println("DEBUG: MessageDAO.getConversations for user: " + userId);
            
            String sql = "SELECT c.conversation_id, " +
                        "CASE WHEN c.user1_id = ? THEN c.user2_id ELSE c.user1_id END as other_user_id, " +
                        "u.full_name, u.email, c.last_message_at, " +
                        "(SELECT m.message_text FROM messages m WHERE m.conversation_id = c.conversation_id ORDER BY m.sent_at DESC FETCH FIRST 1 ROWS ONLY) as last_message " +
                        "FROM conversations c " +
                        "JOIN users u ON (c.user1_id = ? AND u.user_id = c.user2_id) OR (c.user2_id = ? AND u.user_id = c.user1_id) " +
                        "WHERE c.user1_id = ? OR c.user2_id = ? " +
                        "ORDER BY c.last_message_at DESC NULLS LAST";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ps.setInt(2, userId);
            ps.setInt(3, userId);
            ps.setInt(4, userId);
            ps.setInt(5, userId);
            
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> conv = new HashMap<>();
                conv.put("conversationId", rs.getInt("conversation_id"));
                conv.put("otherUserId", rs.getInt("other_user_id"));
                conv.put("fullName", rs.getString("full_name"));
                conv.put("email", rs.getString("email"));
                
                Timestamp lastMsgAt = rs.getTimestamp("last_message_at");
                conv.put("lastMessageAt", lastMsgAt != null ? lastMsgAt.toString() : "");
                conv.put("lastMessage", rs.getString("last_message"));
                conversations.add(conv);
                
                System.out.println("DEBUG: Found conversation " + rs.getInt("conversation_id") + " with user " + rs.getInt("other_user_id"));
            }
            
            System.out.println("DEBUG: MessageDAO found " + conversations.size() + " conversations");
            
        } catch (SQLException e) {
            System.err.println("ERROR in MessageDAO.getConversations: " + e.getMessage());
            e.printStackTrace();
        }
        
        return conversations;
    }
    
    /**
     * Get chat history between two users
     * FIXED: Now queries by conversation_id
     */
    public List<Message> getChatHistory(int userId1, int userId2) {
        List<Message> messages = new ArrayList<>();
        
        try (Connection conn = util.DBConnection.getConnection()) {
            
            System.out.println("DEBUG: MessageDAO.getChatHistory between " + userId1 + " and " + userId2);
            
            // Step 1: Get the conversation_id
            int conversationId = getConversationId(userId1, userId2);
            if (conversationId == -1) {
                System.out.println("DEBUG: No conversation found between " + userId1 + " and " + userId2);
                return messages;
            }
            
            // Step 2: Get messages for this specific conversation
            String sql = "SELECT message_id, conversation_id, sender_id, message_text, sent_at " +
                        "FROM messages " +
                        "WHERE conversation_id = ? " +
                        "ORDER BY sent_at ASC";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, conversationId);
            
            System.out.println("DEBUG: Executing query for conversation: " + conversationId);
            
            ResultSet rs = ps.executeQuery();
            int count = 0;
            
            while (rs.next()) {
                Message msg = new Message();
                msg.setMessageId(rs.getInt("message_id"));
                msg.setConversationId(rs.getInt("conversation_id"));
                msg.setSenderId(rs.getInt("sender_id"));
                msg.setMessageText(rs.getString("message_text"));
                
                Timestamp sentAt = rs.getTimestamp("sent_at");
                msg.setSentAt(sentAt != null ? sentAt.toString() : "");
                
                messages.add(msg);
                count++;
            }
            
            System.out.println("DEBUG: MessageDAO found " + count + " messages in conversation " + conversationId);
            
        } catch (SQLException e) {
            System.err.println("ERROR in MessageDAO.getChatHistory: " + e.getMessage());
            e.printStackTrace();
        }
        
        return messages;
    }
    
    /**
     * Get conversation ID between two users
     */
    private int getConversationId(int userId1, int userId2) {
        int u1 = Math.min(userId1, userId2);
        int u2 = Math.max(userId1, userId2);
        
        try (Connection conn = util.DBConnection.getConnection()) {
            
            String sql = "SELECT conversation_id FROM conversations WHERE user1_id = ? AND user2_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, u1);
            ps.setInt(2, u2);
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                int conversationId = rs.getInt("conversation_id");
                System.out.println("DEBUG: Found conversation " + conversationId + " between " + u1 + " and " + u2);
                return conversationId;
            }
            
        } catch (SQLException e) {
            System.err.println("ERROR in getConversationId: " + e.getMessage());
            e.printStackTrace();
        }
        
        return -1;
    }
    
    /**
     * Save a message to conversation
     * FIXED: Now uses conversation_id, not concern_id
     */
    public boolean saveMessage(int senderId, int conversationId, String messageText) {
        try (Connection conn = util.DBConnection.getConnection()) {
            
            System.out.println("DEBUG: MessageDAO.saveMessage from user " + senderId + " in conversation " + conversationId);
            System.out.println("DEBUG: Message text: " + messageText);
            
            String sql = "INSERT INTO messages (message_id, conversation_id, sender_id, message_text, sent_at) " +
                        "VALUES (messages_seq.NEXTVAL, ?, ?, ?, SYSDATE)";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, conversationId);
            ps.setInt(2, senderId);
            ps.setString(3, messageText);
            
            int rows = ps.executeUpdate();
            System.out.println("DEBUG: MessageDAO inserted " + rows + " row(s)");
            
            if (rows > 0) {
                updateConversationTimestamp(conversationId);
            }
            
            return rows > 0;
            
        } catch (SQLException e) {
            System.err.println("ERROR in MessageDAO.saveMessage: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Update last_message_at timestamp
     */
    private void updateConversationTimestamp(int conversationId) {
        try (Connection conn = util.DBConnection.getConnection()) {
            
            String sql = "UPDATE conversations SET last_message_at = SYSDATE WHERE conversation_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, conversationId);
            ps.executeUpdate();
            
            System.out.println("DEBUG: Updated last_message_at for conversation " + conversationId);
            
        } catch (SQLException e) {
            System.err.println("ERROR in updateConversationTimestamp: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Get user by email
     */
    public Map<String, Object> getUserByEmail(String email) {
        try (Connection conn = util.DBConnection.getConnection()) {
            
            System.out.println("DEBUG: MessageDAO.getUserByEmail - Looking for: " + email);
            
            String sql = "SELECT user_id, full_name, email FROM users WHERE LOWER(email) = LOWER(?) AND role_id = 1";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, email.trim());
            
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                Map<String, Object> user = new HashMap<>();
                user.put("id", rs.getInt("user_id"));
                user.put("fullName", rs.getString("full_name"));
                user.put("email", rs.getString("email"));
                
                System.out.println("DEBUG: MessageDAO found user: " + rs.getString("full_name"));
                return user;
            }
            
            System.out.println("DEBUG: MessageDAO found no user with email: " + email);
            
        } catch (SQLException e) {
            System.err.println("ERROR in MessageDAO.getUserByEmail: " + e.getMessage());
            e.printStackTrace();
        }
        
        return null;
    }
    
    /**
     * Create or get conversation between two users
     * FIXED: Now returns int (conversationId)
     */
    public int createOrGetConversation(int userId1, int userId2) {
        int u1 = Math.min(userId1, userId2);
        int u2 = Math.max(userId1, userId2);
        
        try (Connection conn = util.DBConnection.getConnection()) {
            
            System.out.println("DEBUG: MessageDAO.createOrGetConversation between " + u1 + " and " + u2);
            
            // Check if exists
            String checkSql = "SELECT conversation_id FROM conversations WHERE user1_id = ? AND user2_id = ?";
            PreparedStatement checkPs = conn.prepareStatement(checkSql);
            checkPs.setInt(1, u1);
            checkPs.setInt(2, u2);
            
            ResultSet rs = checkPs.executeQuery();
            if (rs.next()) {
                int conversationId = rs.getInt("conversation_id");
                System.out.println("DEBUG: Conversation already exists with ID: " + conversationId);
                return conversationId;
            }
            
            // Create new conversation
            String insertSql = "INSERT INTO conversations (conversation_id, user1_id, user2_id, last_message_at) " +
                             "VALUES (conversations_seq.NEXTVAL, ?, ?, NULL)";
            PreparedStatement insertPs = conn.prepareStatement(insertSql);
            insertPs.setInt(1, u1);
            insertPs.setInt(2, u2);
            int rows = insertPs.executeUpdate();
            
            if (rows > 0) {
                // Get the new conversation ID
                String getSql = "SELECT conversation_id FROM conversations WHERE user1_id = ? AND user2_id = ?";
                PreparedStatement getPs = conn.prepareStatement(getSql);
                getPs.setInt(1, u1);
                getPs.setInt(2, u2);
                
                ResultSet getResult = getPs.executeQuery();
                if (getResult.next()) {
                    int conversationId = getResult.getInt("conversation_id");
                    System.out.println("DEBUG: New conversation created with ID: " + conversationId);
                    return conversationId;
                }
            }
            
        } catch (SQLException e) {
            System.err.println("ERROR in MessageDAO.createOrGetConversation: " + e.getMessage());
            e.printStackTrace();
        }
        
        return -1;
    }
}