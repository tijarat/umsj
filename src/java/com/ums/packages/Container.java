package com.ums.packages;

import jakarta.servlet.http.HttpSession;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;

public class Container
{
    private final List<UserSession> userSessions = new ArrayList<>();
    private static class UserSession
    {
        private final String userName;
        private final HttpSession session;
        private UserSession(String userName, HttpSession session)
        {
            this.userName = userName;
            this.session = session;
        }
    }

    public Container(){}
    public synchronized int getCurrentLogedIn(){return userSessions.size();}
    public synchronized void addUser(String userName, HttpSession session)
    {
        if(userName == null || session == null) return;
        userSessions.add(new UserSession(userName, session));
    }

    public synchronized void removeUser(String userName)
    {
        if(userName == null) return;
        for(int i = 0; i < userSessions.size(); i++)
        {
            if(userName.equals(userSessions.get(i).userName))
            {
                userSessions.remove(i);
                return;
            }
        }
    }

    public synchronized HttpSession getUserSession(String userName)
    {
        if(userName == null) return null;
        for(UserSession userSession : userSessions)
            if(userName.equals(userSession.userName)) return userSession.session;
        return null;
    }

    public synchronized Enumeration<String> getUsers()
    {
        if(userSessions.isEmpty()) return null;
        List<String> users = new ArrayList<>();
        for(UserSession userSession : userSessions) users.add(userSession.userName);
        return Collections.enumeration(users);
    }

    public synchronized Enumeration<HttpSession> getSessions()
    {
        if(userSessions.isEmpty()) return null;
        List<HttpSession> sessions = new ArrayList<>();
        for(UserSession userSession : userSessions) sessions.add(userSession.session);
        return Collections.enumeration(sessions);
    }

    public synchronized boolean isUserExisit(String userName)
    {
        if(userName == null) return false;
        for(UserSession userSession : userSessions)
            if(userName.equals(userSession.userName)) return true;
        return false;
    }

    public synchronized boolean isUserExisitTwice(String userName)
    {
        if(userName == null) return false;
        int count = 0;
        for(UserSession userSession : userSessions)
        {
            if(userName.equals(userSession.userName))
            {
                count++;
                if(count > 1) return true;
            }
        }
        return false;
    }

    public synchronized boolean isSessionExisit(String userName)
    {
        return getUserSession(userName) != null;
    }
}