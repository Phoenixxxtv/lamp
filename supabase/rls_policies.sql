-- =============================================================================
-- LAMP App Row-Level Security Policies
-- Run this AFTER schema.sql in Supabase SQL Editor
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Get current user's role
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user is chaperone
CREATE OR REPLACE FUNCTION public.is_chaperone()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'chaperone');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user is chaperone of a specific protege
CREATE OR REPLACE FUNCTION public.is_chaperone_of(protege_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = protege_id AND chaperone_id = auth.uid()
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- =============================================================================
-- PROFILES POLICIES
-- =============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (id = auth.uid());

-- Admin can view all profiles
CREATE POLICY "Admin can view all profiles"
    ON public.profiles FOR SELECT
    USING (public.is_admin());

-- Chaperone can view assigned protégés
CREATE POLICY "Chaperone can view assigned proteges"
    ON public.profiles FOR SELECT
    USING (chaperone_id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid() AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()));

-- Admin can update any profile
CREATE POLICY "Admin can update any profile"
    ON public.profiles FOR UPDATE
    USING (public.is_admin());

-- Admin can delete users
CREATE POLICY "Admin can delete users"
    ON public.profiles FOR DELETE
    USING (public.is_admin());

-- =============================================================================
-- INTERESTS POLICIES
-- =============================================================================

-- All authenticated users can read interests
CREATE POLICY "Anyone can read interests"
    ON public.interests FOR SELECT
    TO authenticated
    USING (true);

-- Only admin can manage interests
CREATE POLICY "Admin can manage interests"
    ON public.interests FOR ALL
    USING (public.is_admin());

-- =============================================================================
-- USER INTERESTS POLICIES
-- =============================================================================

-- Users can view their own interests
CREATE POLICY "Users can view own interests"
    ON public.user_interests FOR SELECT
    USING (user_id = auth.uid());

-- Users can manage their own interests
CREATE POLICY "Users can manage own interests"
    ON public.user_interests FOR ALL
    USING (user_id = auth.uid());

-- Admin can view all user interests
CREATE POLICY "Admin can view all user interests"
    ON public.user_interests FOR SELECT
    USING (public.is_admin());

-- =============================================================================
-- INVITATIONS POLICIES (Admin only)
-- =============================================================================

CREATE POLICY "Admin can manage invitations"
    ON public.invitations FOR ALL
    USING (public.is_admin());

-- Allow checking invitation by code (for signup flow)
CREATE POLICY "Anyone can check invitation by code"
    ON public.invitations FOR SELECT
    TO anon
    USING (true);

-- =============================================================================
-- HABITS POLICIES
-- =============================================================================

-- Admin/Chaperone can create habits
CREATE POLICY "Admin and Chaperone can create habits"
    ON public.habits FOR INSERT
    WITH CHECK (public.is_admin() OR public.is_chaperone());

-- Admin/Chaperone can update/delete their habits
CREATE POLICY "Admin and Chaperone can manage habits"
    ON public.habits FOR ALL
    USING (public.is_admin() OR created_by = auth.uid());

-- Users can view habits assigned to them
CREATE POLICY "Users can view assigned habits"
    ON public.habits FOR SELECT
    USING (
        public.is_admin() 
        OR created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.habit_assignments 
            WHERE habit_id = habits.id AND protege_id = auth.uid()
        )
    );

-- =============================================================================
-- HABIT ASSIGNMENTS POLICIES
-- =============================================================================

-- Admin can assign to anyone
CREATE POLICY "Admin can assign habits to anyone"
    ON public.habit_assignments FOR INSERT
    WITH CHECK (public.is_admin());

-- Chaperone can assign only to their protégés
CREATE POLICY "Chaperone can assign habits to proteges"
    ON public.habit_assignments FOR INSERT
    WITH CHECK (public.is_chaperone_of(protege_id));

-- Users can view their assignments
CREATE POLICY "Users can view own habit assignments"
    ON public.habit_assignments FOR SELECT
    USING (
        protege_id = auth.uid() 
        OR assigned_by = auth.uid() 
        OR public.is_admin()
        OR public.is_chaperone_of(protege_id)
    );

-- Admin/Chaperone can delete assignments
CREATE POLICY "Admin and Chaperone can delete assignments"
    ON public.habit_assignments FOR DELETE
    USING (public.is_admin() OR assigned_by = auth.uid());

-- =============================================================================
-- HABIT COMPLETIONS POLICIES
-- =============================================================================

-- Users can log their own completions
CREATE POLICY "Users can log own habit completions"
    ON public.habit_completions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.habit_assignments 
            WHERE id = habit_assignment_id AND protege_id = auth.uid()
        )
    );

-- Users can view their own completions
CREATE POLICY "Users can view own completions"
    ON public.habit_completions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.habit_assignments ha
            WHERE ha.id = habit_assignment_id 
            AND (ha.protege_id = auth.uid() OR ha.assigned_by = auth.uid())
        )
        OR public.is_admin()
    );

-- Chaperone can view protégé completions
CREATE POLICY "Chaperone can view protege completions"
    ON public.habit_completions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.habit_assignments ha
            WHERE ha.id = habit_assignment_id 
            AND public.is_chaperone_of(ha.protege_id)
        )
    );

-- =============================================================================
-- TASKS POLICIES
-- =============================================================================

-- Admin/Chaperone can create tasks
CREATE POLICY "Admin and Chaperone can create tasks"
    ON public.tasks FOR INSERT
    WITH CHECK (public.is_admin() OR public.is_chaperone());

-- Admin/Chaperone can manage their tasks
CREATE POLICY "Admin and Chaperone can manage tasks"
    ON public.tasks FOR ALL
    USING (public.is_admin() OR created_by = auth.uid());

-- Users can view assigned tasks
CREATE POLICY "Users can view assigned tasks"
    ON public.tasks FOR SELECT
    USING (
        public.is_admin() 
        OR created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.task_assignments 
            WHERE task_id = tasks.id AND protege_id = auth.uid()
        )
    );

-- =============================================================================
-- TASK ASSIGNMENTS POLICIES
-- =============================================================================

-- Admin can assign to anyone
CREATE POLICY "Admin can assign tasks to anyone"
    ON public.task_assignments FOR INSERT
    WITH CHECK (public.is_admin());

-- Chaperone can assign only to their protégés
CREATE POLICY "Chaperone can assign tasks to proteges"
    ON public.task_assignments FOR INSERT
    WITH CHECK (public.is_chaperone_of(protege_id));

-- Users can view their task assignments
CREATE POLICY "Users can view own task assignments"
    ON public.task_assignments FOR SELECT
    USING (
        protege_id = auth.uid() 
        OR assigned_by = auth.uid() 
        OR public.is_admin()
        OR public.is_chaperone_of(protege_id)
    );

-- Protégé can submit their tasks
CREATE POLICY "Protege can submit tasks"
    ON public.task_assignments FOR UPDATE
    USING (protege_id = auth.uid())
    WITH CHECK (protege_id = auth.uid());

-- Chaperone can verify tasks of their protégés
CREATE POLICY "Chaperone can verify protege tasks"
    ON public.task_assignments FOR UPDATE
    USING (public.is_chaperone_of(protege_id) OR public.is_admin());

-- =============================================================================
-- COMMUNITY POSTS POLICIES
-- =============================================================================

-- All authenticated users can read posts
CREATE POLICY "Anyone can read community posts"
    ON public.community_posts FOR SELECT
    TO authenticated
    USING (true);

-- All authenticated users can create posts
CREATE POLICY "Anyone can create community posts"
    ON public.community_posts FOR INSERT
    TO authenticated
    WITH CHECK (author_id = auth.uid());

-- Users can update their own posts
CREATE POLICY "Users can update own posts"
    ON public.community_posts FOR UPDATE
    USING (author_id = auth.uid());

-- Users can delete their own posts, Admin can delete any
CREATE POLICY "Users can delete own posts"
    ON public.community_posts FOR DELETE
    USING (author_id = auth.uid() OR public.is_admin());

-- =============================================================================
-- COMMUNITY REPLIES POLICIES
-- =============================================================================

-- All authenticated users can read replies
CREATE POLICY "Anyone can read community replies"
    ON public.community_replies FOR SELECT
    TO authenticated
    USING (true);

-- All authenticated users can create replies
CREATE POLICY "Anyone can create community replies"
    ON public.community_replies FOR INSERT
    TO authenticated
    WITH CHECK (author_id = auth.uid());

-- Users can update their own replies
CREATE POLICY "Users can update own replies"
    ON public.community_replies FOR UPDATE
    USING (author_id = auth.uid());

-- Users can delete own replies, Admin can delete any
CREATE POLICY "Users can delete own replies"
    ON public.community_replies FOR DELETE
    USING (author_id = auth.uid() OR public.is_admin());

-- =============================================================================
-- NOTIFICATIONS POLICIES
-- =============================================================================

-- Users can only see their own notifications
CREATE POLICY "Users can view own notifications"
    ON public.notifications FOR SELECT
    USING (user_id = auth.uid());

-- Users can mark their notifications as read
CREATE POLICY "Users can update own notifications"
    ON public.notifications FOR UPDATE
    USING (user_id = auth.uid());

-- System/Admin can create notifications (via service role)
CREATE POLICY "Service can create notifications"
    ON public.notifications FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
    ON public.notifications FOR DELETE
    USING (user_id = auth.uid());
