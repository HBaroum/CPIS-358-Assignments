<%@ Page Language="C#" MasterPageFile="Site.master" AutoEventWireup="true" %>

<script runat="server">
    protected int CurrentUserId
    {
        get { return Convert.ToInt32(Session["UserID"]); }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        DatabaseHelper.Initialize();

        if (Session["UserID"] == null)
        {
            Response.Redirect("Login.aspx");
            return;
        }

        if (!IsPostBack)
        {
            if (Request.QueryString["created"] == "1")
            {
                pnlAccountCreatedMessage.Visible = true;
                lblAccountCreatedTitle.Text = "Account Created Successfully";
                lblAccountCreatedText.Text = "Welcome, " + Session["FullName"].ToString() +
                    "! Your account has been created successfully. You can now create your own study session or join another student with the same course and study goal.";
            }
            else
            {
                pnlAccountCreatedMessage.Visible = false;
            }

            lblSessionUserId.Text   = Session["UserID"].ToString();
            lblSessionFullName.Text = Session["FullName"].ToString();
            lblSessionEmail.Text    = Session["Email"].ToString();

            lblWelcome.Text = "Welcome, " + Session["FullName"].ToString() +
                              ". Create your own study session, or join another student who has the same course and study goal.";

            HttpCookie courseCookie = Request.Cookies["StudySyncPreferredCourse"];

            if (courseCookie != null)
            {
                lblCookieInfo.Text    = "Cookie loaded: preferred course = " + courseCookie.Value;
                txtCourse.Text        = courseCookie.Value;
                btnClearCookie.Visible = true;
            }
            else
            {
                lblCookieInfo.Text    = "No preferred-course cookie found. Add a session to set one.";
                btnClearCookie.Visible = false;
            }

            BindMyGrid("");
            BindAvailableGrid("");
        }
    }

    private void BindMyGrid(string keyword)
    {
        gvMySessions.DataSource = DatabaseHelper.GetMyStudySessions(CurrentUserId, keyword);
        gvMySessions.DataBind();
    }

    private void BindAvailableGrid(string keyword)
    {
        gvAvailableSessions.DataSource = DatabaseHelper.GetAvailableStudySessions(CurrentUserId, keyword);
        gvAvailableSessions.DataBind();
    }

    protected void btnAdd_Click(object sender, EventArgs e)
    {
        if (!Page.IsValid) return;

        DatabaseHelper.AddStudySession(
            CurrentUserId,
            txtCourse.Text.Trim(),
            ddlGoal.SelectedValue,
            txtTime.Text.Trim(),
            ddlMode.SelectedValue,
            txtNotes.Text.Trim()
        );

        HttpCookie lastCourseCookie = new HttpCookie("StudySyncPreferredCourse", txtCourse.Text.Trim());
        lastCourseCookie.Expires = DateTime.Now.AddDays(14);
        lastCourseCookie.Path = "/";
        Response.Cookies.Add(lastCourseCookie);

        lblCookieInfo.Text     = "Cookie saved: preferred course = " + txtCourse.Text.Trim();
        btnClearCookie.Visible = true;

        lblStatus.Text     = "Study session inserted successfully.";
        lblStatus.CssClass = "success-message";

        ClearForm();
        BindMyGrid(txtSearch.Text.Trim());
        BindAvailableGrid(txtAvailableSearch.Text.Trim());
    }

    protected void btnUpdate_Click(object sender, EventArgs e)
    {
        if (string.IsNullOrWhiteSpace(hfSessionId.Value))
        {
            lblStatus.Text     = "&#9888; No session selected. Click the 'Edit' button on one of your sessions first, then press Update.";
            lblStatus.CssClass = "error-message";
            return;
        }

        DatabaseHelper.UpdateStudySession(
            Convert.ToInt32(hfSessionId.Value),
            CurrentUserId,
            txtCourse.Text.Trim(),
            ddlGoal.SelectedValue,
            txtTime.Text.Trim(),
            ddlMode.SelectedValue,
            txtNotes.Text.Trim()
        );

        lblStatus.Text     = "Your study session was updated successfully.";
        lblStatus.CssClass = "success-message";

        ClearForm();
        BindMyGrid(txtSearch.Text.Trim());
        BindAvailableGrid(txtAvailableSearch.Text.Trim());
    }

    protected void btnSearch_Click(object sender, EventArgs e)
    {
        BindMyGrid(txtSearch.Text.Trim());
        lblStatus.Text     = "Search completed for your own sessions.";
        lblStatus.CssClass = "success-message";
    }

    protected void btnShowAll_Click(object sender, EventArgs e)
    {
        txtSearch.Text = "";
        BindMyGrid("");
        lblStatus.Text     = "All your sessions are displayed.";
        lblStatus.CssClass = "success-message";
    }

    protected void btnAvailableSearch_Click(object sender, EventArgs e)
    {
        BindAvailableGrid(txtAvailableSearch.Text.Trim());
        lblJoinStatus.Text     = "Available study sessions search completed.";
        lblJoinStatus.CssClass = "success-message";
    }

    protected void btnAvailableShowAll_Click(object sender, EventArgs e)
    {
        txtAvailableSearch.Text = "";
        BindAvailableGrid("");
        lblJoinStatus.Text     = "All available study sessions are displayed.";
        lblJoinStatus.CssClass = "success-message";
    }

    protected void btnClear_Click(object sender, EventArgs e)
    {
        ClearForm();
        lblStatus.Text = "";
        lblStatus.CssClass = "";
    }

    protected void btnClearCookie_Click(object sender, EventArgs e)
    {
        HttpCookie expiredCookie = new HttpCookie("StudySyncPreferredCourse");
        expiredCookie.Expires = DateTime.Now.AddDays(-1);
        expiredCookie.Path = "/";
        Response.Cookies.Add(expiredCookie);

        lblCookieInfo.Text     = "Cookie deleted. No preferred course is stored.";
        btnClearCookie.Visible = false;
        txtCourse.Text         = "";

        lblStatus.Text     = "Cookie cleared successfully.";
        lblStatus.CssClass = "success-message";
    }

    protected void gvMySessions_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
    {
        int sessionId = Convert.ToInt32(e.CommandArgument);

        if (e.CommandName == "EditSession")
        {
            System.Data.DataTable table = DatabaseHelper.GetStudySessionById(sessionId, CurrentUserId);

            if (table.Rows.Count > 0)
            {
                System.Data.DataRow row = table.Rows[0];

                hfSessionId.Value     = row["SessionId"].ToString();
                txtCourse.Text        = row["Course"].ToString();
                ddlGoal.SelectedValue = row["StudyGoal"].ToString();
                txtTime.Text          = row["AvailableTime"].ToString();
                ddlMode.SelectedValue = row["PreferredMode"].ToString();
                txtNotes.Text         = row["Notes"].ToString();

                lblStatus.Text     = "Your record is loaded for updating.";
                lblStatus.CssClass = "success-message";
            }
            else
            {
                lblStatus.Text     = "You can only edit your own study sessions.";
                lblStatus.CssClass = "error-message";
            }
        }
        else if (e.CommandName == "DeleteSession")
        {
            DatabaseHelper.DeleteStudySession(sessionId, CurrentUserId);

            lblStatus.Text     = "Your study session was deleted successfully.";
            lblStatus.CssClass = "success-message";

            BindMyGrid(txtSearch.Text.Trim());
            BindAvailableGrid(txtAvailableSearch.Text.Trim());
        }
    }

    protected void gvAvailableSessions_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
    {
        if (e.CommandName == "JoinSession")
        {
            int sessionId = Convert.ToInt32(e.CommandArgument);
            bool joined   = DatabaseHelper.JoinSession(sessionId, CurrentUserId);

            if (joined)
            {
                lblJoinStatus.Text     = "You joined this study session successfully. Your name will now appear in the joined students list.";
                lblJoinStatus.CssClass = "success-message";
            }
            else
            {
                lblJoinStatus.Text     = "This is your own study session. Other students can join it.";
                lblJoinStatus.CssClass = "error-message";
            }

            BindMyGrid(txtSearch.Text.Trim());
            BindAvailableGrid(txtAvailableSearch.Text.Trim());
        }
    }

    private void ClearForm()
    {
        hfSessionId.Value      = "";
        txtCourse.Text         = "";
        ddlGoal.SelectedIndex  = 0;
        txtTime.Text           = "";
        ddlMode.SelectedIndex  = 0;
        txtNotes.Text          = "";
    }
</script>

<asp:Content ID="Title" ContentPlaceHolderID="TitleContent" runat="server">
    StudySync - Dashboard
</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">

    <asp:Panel ID="pnlAccountCreatedMessage" runat="server" CssClass="account-created-panel" Visible="false">
        <h2>
            <asp:Label ID="lblAccountCreatedTitle" runat="server"></asp:Label>
        </h2>
        <p>
            <asp:Label ID="lblAccountCreatedText" runat="server"></asp:Label>
        </p>
    </asp:Panel>

    <!-- ── Active Session Info ── -->
    <section class="info-box session-info-box">
        <h3>&#128274; Active Session Data</h3>
        <p>The following values are currently stored in the <strong>ASP.NET Session</strong>:</p>
        <table class="info-table">
            <tr>
                <th>Session Key</th>
                <th>Session Value</th>
            </tr>
            <tr>
                <td>UserID</td>
                <td><asp:Label ID="lblSessionUserId" runat="server"></asp:Label></td>
            </tr>
            <tr>
                <td>FullName</td>
                <td><asp:Label ID="lblSessionFullName" runat="server"></asp:Label></td>
            </tr>
            <tr>
                <td>Email</td>
                <td><asp:Label ID="lblSessionEmail" runat="server"></asp:Label></td>
            </tr>
        </table>
        <p style="margin-top:10px; font-size:0.9em; color:#555;">
            Session is cleared when you <a href="Logout.aspx">Logout</a>.
        </p>
    </section>

    <!-- ── Cookie Status ── -->
    <section class="info-box cookie-info-box">
        <h3>&#127850; Cookie Status</h3>
        <asp:Label ID="lblCookieInfo" runat="server" CssClass="note"></asp:Label>
        <asp:Button ID="btnClearCookie" runat="server"
            Text="Delete Cookie"
            OnClick="btnClearCookie_Click"
            CausesValidation="false"
            CssClass="btn-danger" />
    </section>

    <!-- ── Add / Update Form ── -->
    <section class="form-container">
        <h2>Dashboard &mdash; My Study Sessions</h2>
        <asp:Label ID="lblWelcome" runat="server" CssClass="note"></asp:Label>

        <asp:HiddenField ID="hfSessionId" runat="server" />

        <h3>Add or Update a Study Session</h3>

        <label for="<%= txtCourse.ClientID %>">Course:</label>
        <asp:TextBox ID="txtCourse" runat="server" placeholder="Example: CPIS-358"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvCourse" runat="server"
            ControlToValidate="txtCourse"
            ErrorMessage="Course is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= ddlGoal.ClientID %>">Study Goal:</label>
        <asp:DropDownList ID="ddlGoal" runat="server">
            <asp:ListItem Value="">Select goal</asp:ListItem>
            <asp:ListItem>Exam Preparation</asp:ListItem>
            <asp:ListItem>Quiz Review</asp:ListItem>
            <asp:ListItem>Assignment Help</asp:ListItem>
            <asp:ListItem>Project Work</asp:ListItem>
        </asp:DropDownList>
        <asp:RequiredFieldValidator ID="rfvGoal" runat="server"
            ControlToValidate="ddlGoal"
            InitialValue=""
            ErrorMessage="Study goal is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= txtTime.ClientID %>">Available Time:</label>
        <asp:TextBox ID="txtTime" runat="server" placeholder="Example: 6 PM - 8 PM"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvTime" runat="server"
            ControlToValidate="txtTime"
            ErrorMessage="Available time is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= ddlMode.ClientID %>">Preferred Mode:</label>
        <asp:DropDownList ID="ddlMode" runat="server">
            <asp:ListItem Value="">Select mode</asp:ListItem>
            <asp:ListItem>Online</asp:ListItem>
            <asp:ListItem>In-Person</asp:ListItem>
        </asp:DropDownList>
        <asp:RequiredFieldValidator ID="rfvMode" runat="server"
            ControlToValidate="ddlMode"
            InitialValue=""
            ErrorMessage="Preferred mode is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= txtNotes.ClientID %>">Notes (Optional):</label>
        <asp:TextBox ID="txtNotes" runat="server" TextMode="MultiLine" Rows="3" placeholder="Optional notes"></asp:TextBox>

        <div class="button-row">
            <asp:Button ID="btnAdd"    runat="server" Text="Insert" OnClick="btnAdd_Click" />
            <asp:Button ID="btnUpdate" runat="server" Text="Update" OnClick="btnUpdate_Click" />
            <asp:Button ID="btnClear"  runat="server" Text="Clear"  OnClick="btnClear_Click" CausesValidation="false" CssClass="btn-secondary" />
        </div>

        <asp:Label ID="lblStatus" runat="server"></asp:Label>
    </section>

    <!-- ── My Sessions Grid ── -->
    <section class="table-section">
        <h2>My Study Sessions</h2>
        <p class="note">Only your own sessions can be edited or deleted. Joined students are displayed in the same row.</p>

        <div class="search-row">
            <asp:TextBox ID="txtSearch" runat="server" placeholder="Search your sessions..."></asp:TextBox>
            <asp:Button ID="btnSearch"  runat="server" Text="Search"   OnClick="btnSearch_Click"  CausesValidation="false" />
            <asp:Button ID="btnShowAll" runat="server" Text="Show All" OnClick="btnShowAll_Click" CausesValidation="false" CssClass="btn-secondary" />
        </div>

        <div class="grid-scroll-wrapper">
        <asp:GridView ID="gvMySessions" runat="server"
            AutoGenerateColumns="False"
            CssClass="grid"
            OnRowCommand="gvMySessions_RowCommand"
            DataKeyNames="SessionId">
            <Columns>
                <asp:BoundField DataField="SessionId"     HeaderText="ID" />
                <asp:BoundField DataField="Course"        HeaderText="Course" />
                <asp:BoundField DataField="StudyGoal"     HeaderText="Goal" />
                <asp:BoundField DataField="AvailableTime" HeaderText="Time" />
                <asp:BoundField DataField="PreferredMode" HeaderText="Mode" />
                <asp:BoundField DataField="Notes"         HeaderText="Notes" />
                <asp:BoundField DataField="JoinedStudents" HeaderText="Joined Students" />
                <asp:BoundField DataField="CreatedAt"     HeaderText="Created At" />
                <asp:TemplateField HeaderText="Actions">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkEdit" runat="server"
                            Text="Edit"
                            CommandName="EditSession"
                            CommandArgument='<%# Eval("SessionId") %>'
                            CausesValidation="false">
                        </asp:LinkButton>
                        &nbsp;|&nbsp;
                        <asp:LinkButton ID="lnkDelete" runat="server"
                            Text="Delete"
                            CommandName="DeleteSession"
                            CommandArgument='<%# Eval("SessionId") %>'
                            CausesValidation="false"
                            OnClientClick="return confirm('Are you sure you want to delete this session?');">
                        </asp:LinkButton>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
        </div>
    </section>
    <section class="table-section">
        <h2>Available Study Partners &mdash; Join a Session</h2>
        <p class="note">
            All logged-in students can view and join sessions here. Students cannot edit or delete sessions created by others.
            Sessions with the same course and goal appear first.
        </p>

        <div class="search-row">
            <asp:TextBox ID="txtAvailableSearch" runat="server" placeholder="Search by course, goal, mode, or student name..."></asp:TextBox>
            <asp:Button ID="btnAvailableSearch"  runat="server" Text="Search"   OnClick="btnAvailableSearch_Click"  CausesValidation="false" />
            <asp:Button ID="btnAvailableShowAll" runat="server" Text="Show All" OnClick="btnAvailableShowAll_Click" CausesValidation="false" CssClass="btn-secondary" />
        </div>

        <asp:Label ID="lblJoinStatus" runat="server"></asp:Label>

        <div class="grid-scroll-wrapper">
        <asp:GridView ID="gvAvailableSessions" runat="server"
            AutoGenerateColumns="False"
            CssClass="grid"
            OnRowCommand="gvAvailableSessions_RowCommand"
            DataKeyNames="SessionId">
            <Columns>
                <asp:BoundField DataField="SessionId"     HeaderText="ID" />
                <asp:BoundField DataField="MatchStatus"   HeaderText="Match" />
                <asp:BoundField DataField="CreatedBy"     HeaderText="Created By" />
                <asp:BoundField DataField="Course"        HeaderText="Course" />
                <asp:BoundField DataField="StudyGoal"     HeaderText="Goal" />
                <asp:BoundField DataField="AvailableTime" HeaderText="Time" />
                <asp:BoundField DataField="PreferredMode" HeaderText="Mode" />
                <asp:BoundField DataField="Notes"         HeaderText="Notes" />
                <asp:BoundField DataField="JoinedStudents" HeaderText="Joined Students" />
                <asp:BoundField DataField="JoinedCount"   HeaderText="Count" />
                <asp:TemplateField HeaderText="Join">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkJoin" runat="server"
                            Text="Join"
                            CommandName="JoinSession"
                            CommandArgument='<%# Eval("SessionId") %>'
                            CausesValidation="false"
                            Visible='<%# Convert.ToInt32(Eval("OwnerUserId")) != CurrentUserId && Eval("AlreadyJoined").ToString() == "No" %>'>
                        </asp:LinkButton>
                        <asp:Label ID="lblJoined" runat="server"
                            Text="&#10003; Joined"
                            CssClass="joined-badge"
                            Visible='<%# Convert.ToInt32(Eval("OwnerUserId")) != CurrentUserId && Eval("AlreadyJoined").ToString() == "Yes" %>'>
                        </asp:Label>
                        <asp:Label ID="lblOwner" runat="server"
                            Text="Your session"
                            CssClass="note"
                            Visible='<%# Convert.ToInt32(Eval("OwnerUserId")) == CurrentUserId %>'>
                        </asp:Label>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
        </div>
    </section>

</asp:Content>
