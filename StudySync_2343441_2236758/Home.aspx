<%@ Page Language="C#" MasterPageFile="Site.master" AutoEventWireup="true" %>

<script runat="server">

    private bool IsLoggedIn  { get { return Session["UserID"] != null; } }
    private int  CurrentUser { get { return Convert.ToInt32(Session["UserID"]); } }

    protected void Page_Load(object sender, EventArgs e)
    {
        DatabaseHelper.Initialize();
        heroButtons.Visible = !IsLoggedIn;
        if (!IsPostBack)
            BindSessionsTable();
    }

    private void BindSessionsTable()
    {
        System.Data.DataTable dt = DatabaseHelper.GetAllSessionsForHome();

        if (dt.Rows.Count == 0)
        {
            pnlNoSessions.Visible   = true;
            pnlSessionsGrid.Visible = false;
            return;
        }

        pnlNoSessions.Visible   = false;
        pnlSessionsGrid.Visible = true;
        rptSessions.DataSource  = dt;
        rptSessions.DataBind();
    }

    protected void btnJoinLeave_Click(object sender, EventArgs e)
    {
        if (!IsLoggedIn)
        {
            Response.Redirect("Login.aspx");
            return;
        }

        System.Web.UI.WebControls.Button btn =
            (System.Web.UI.WebControls.Button)sender;

        if (btn.CommandName == "Join")
        {
            int sessionId = Convert.ToInt32(btn.CommandArgument);
            DatabaseHelper.JoinSession(sessionId, CurrentUser);
        }

        BindSessionsTable();
    }

    protected void rptSessions_ItemDataBound(object sender,
        System.Web.UI.WebControls.RepeaterItemEventArgs e)
    {
        if (e.Item.ItemType != System.Web.UI.WebControls.ListItemType.Item &&
            e.Item.ItemType != System.Web.UI.WebControls.ListItemType.AlternatingItem)
            return;

        System.Data.DataRowView row = (System.Data.DataRowView)e.Item.DataItem;
        int sessionId    = Convert.ToInt32(row["SessionId"]);
        int ownerUserId  = Convert.ToInt32(row["OwnerUserId"]);
        int studentCount = Convert.ToInt32(row["StudentCount"]);

        System.Web.UI.WebControls.Label lblCount =
            (System.Web.UI.WebControls.Label)e.Item.FindControl("lblStudentCount");
        lblCount.Text = studentCount.ToString();

        System.Web.UI.WebControls.Button btn =
            (System.Web.UI.WebControls.Button)e.Item.FindControl("btnJoinLeave");
        System.Web.UI.WebControls.Label lblJoinMsg =
            (System.Web.UI.WebControls.Label)e.Item.FindControl("lblJoinMsg");

        if (!IsLoggedIn)
        {
            btn.Text            = "Login to Join";
            btn.CommandName     = "";
            btn.CommandArgument = sessionId.ToString();
            btn.CssClass        = "btn-join-login";
            btn.Enabled         = true;
            lblJoinMsg.Visible  = false;
        }
        else
        {
            bool alreadyJoined = DatabaseHelper.IsUserJoined(sessionId, CurrentUser);

            if (ownerUserId == CurrentUser)
            {
                btn.Text            = "Your session";
                btn.CommandName     = "";
                btn.CommandArgument = sessionId.ToString();
                btn.CssClass        = "btn-owner";
                btn.Enabled         = false;
                lblJoinMsg.Visible  = false;
            }
            else if (alreadyJoined)
            {
                btn.Text            = "✓ Joined";
                btn.CommandName     = "";
                btn.CommandArgument = sessionId.ToString();
                btn.CssClass        = "btn-already-joined";
                btn.Enabled         = false;
                lblJoinMsg.Visible  = true;
                lblJoinMsg.Text     = "Joined";
            }
            else
            {
                btn.Text            = "Join";
                btn.CommandName     = "Join";
                btn.CommandArgument = sessionId.ToString();
                btn.CssClass        = "btn-join";
                btn.Enabled         = true;
                lblJoinMsg.Visible  = false;
            }
        }
    }
</script>

<asp:Content ID="Title" ContentPlaceHolderID="TitleContent" runat="server">StudySync - Home</asp:Content>
<asp:Content ID="Head"  ContentPlaceHolderID="HeadContent"  runat="server"></asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">

    <!-- ══ 1. Hero ══ -->
    <section class="hero">
        <div class="overlay-box">
            <h2 id="heroTitle">Find Your Perfect Study Partner</h2>
            <p  id="heroText">Same course. Same goal. Same time.</p>
            <asp:Panel ID="heroButtons" runat="server">
                <button type="button" onclick="window.location.href='Signup.aspx'">Start Now</button>
                <button type="button" onclick="window.location.href='Login.aspx'" class="btn-secondary">Login</button>
            </asp:Panel>
            <button type="button" id="btnChangeHero"
                    onclick="changeHeroContent()"
                    style="margin-top:8px; background:transparent; color:#1f5fa8;
                           border:1px solid #1f5fa8; font-size:0.82rem; padding:4px 12px;
                           border-radius:14px; cursor:pointer;">
                Change Hero Text
            </button>
            <button type="button"
                    onclick="showWelcome()"
                    style="margin-top:8px; margin-left:6px; background:transparent; color:#1f5fa8;
                           border:1px solid #1f5fa8; font-size:0.82rem; padding:4px 12px;
                           border-radius:14px; cursor:pointer;">
                Show Welcome
            </button>
        </div>
    </section>

    <div id="welcomeAlertBox" style="display:none; background:#dff0d8; color:#3c763d;
         border:1px solid #d6e9c6; border-radius:8px; padding:12px 20px;
         margin:10px auto; width:85%; text-align:center; font-weight:bold;">
        Welcome to StudySync! Find your perfect study partner today.
    </div>

    <!-- ══ 2. Project Idea ══ -->
    <section class="welcome-box">
        <h2>&#128218; Project Idea</h2>
        <p>
            StudySync is a student-focused platform that helps university students find study partners
            based on the same subject, study goal, and available time.
        </p>

        <h2>&#9989; Benefits</h2>
        <ul id="tipList">
            <li>Connect with classmates easily</li>
            <li>Study online or face-to-face</li>
            <li>Save time searching for partners</li>
            <li>Improve motivation and performance</li>
        </ul>
        <button type="button" onclick="addStudyTip()">+ Add Study Tip</button>

        <h2>&#128736; How It Works</h2>
        <ol>
            <li>Create an account</li>
            <li>Select your course and study goal</li>
            <li>Choose your available time</li>
            <li>Find a matching study partner</li>
        </ol>

        <p><a href="#schedule">&#8595; Go to Study Sessions Table</a></p>
    </section>

    <!-- ══ 3. Image Slider ══ -->
    <section class="slider-section">
        <h2>&#127974; Study Life Gallery</h2>
        <p>Browse through our study environment photos.</p>

        <div class="slider-wrapper">
            <div class="slide active">
                <img src="Images/photo2.jpg" alt="Students studying together" />
                <div class="slide-caption">Collaborate with classmates</div>
            </div>
            <div class="slide">
                <img src="Images/photo1.jpg" alt="Study group" />
                <div class="slide-caption">Find your perfect study partner</div>
            </div>
            <div class="slide">
                <img src="Images/photo1.jpg" alt="Online study session" style="filter:brightness(0.85) sepia(0.3);" />
                <div class="slide-caption">Study online or in-person</div>
            </div>
        </div>

        <div class="slider-controls">
            <button type="button" class="slider-btn" onclick="moveSlide(-1)">&#8249;</button>
            <div class="slider-dots">
                <button type="button" class="slider-dot active" onclick="goToSlide(0)"></button>
                <button type="button" class="slider-dot"        onclick="goToSlide(1)"></button>
                <button type="button" class="slider-dot"        onclick="goToSlide(2)"></button>
            </div>
            <button type="button" class="slider-btn" onclick="moveSlide(1)">&#8250;</button>
        </div>
    </section>

    <!-- ══ 4. Dynamic Image ══ -->
    <section class="image-section">
        <h2>&#127775; Dynamic Picture &amp; Text</h2>
        <p id="dynamicText">This text and image change dynamically using JavaScript.</p>
        <div class="compact-image">
            <img id="dynamicImage" src="Images/photo2.jpg" alt="Students Studying" class="main-image" />
        </div>
        <br />
        <button type="button" onclick="changeDynamicPictureAndText()">Change Picture &amp; Text</button>
    </section>

    <!-- ══ 5. Live Study Sessions Table ══ -->
    <section id="schedule" class="table-section">
        <h2>&#128197; Live Study Sessions</h2>
        <p style="color:#555; margin-bottom:12px;">
            Sessions added by students appear here. Log in to join a session and collaborate!
        </p>

        <asp:Panel ID="pnlNoSessions" runat="server" Visible="false">
            <p class="no-sessions-notice">
                No study sessions have been created yet.
                <asp:HyperLink runat="server" NavigateUrl="Dashboard.aspx">Go to Dashboard</asp:HyperLink>
                to add the first one!
            </p>
        </asp:Panel>

        <asp:Panel ID="pnlSessionsGrid" runat="server">
            <table class="sessions-table">
                <thead>
                    <tr>
                        <th>Course</th>
                        <th>Goal</th>
                        <th>Time</th>
                        <th>Mode</th>
                        <th>Created By</th>
                        <th>Students</th>
                        <th>Join</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptSessions" runat="server"
                                  OnItemDataBound="rptSessions_ItemDataBound">
                        <ItemTemplate>
                            <tr>
                                <td><%# Eval("Course") %></td>
                                <td><%# Eval("StudyGoal") %></td>
                                <td><%# Eval("AvailableTime") %></td>
                                <td><%# Eval("PreferredMode") %></td>
                                <td><%# Eval("CreatedBy") %></td>
                                <td>
                                    <span class="count-pill">
                                        <asp:Label ID="lblStudentCount" runat="server" Text="0"></asp:Label>
                                    </span>
                                </td>
                                <td>
                                    <asp:Button ID="btnJoinLeave" runat="server"
                                                Text="Join"
                                                CommandName="Join"
                                                CommandArgument='<%# Eval("SessionId") %>'
                                                CssClass="btn-join"
                                                OnClick="btnJoinLeave_Click"
                                                CausesValidation="false" />
                                    <asp:Label ID="lblJoinMsg" runat="server"
                                               CssClass="joined-badge"
                                               Visible="false"></asp:Label>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </asp:Panel>
    </section>

    <!-- ══ 6. Why StudySync Cards ══ -->
    <section class="article-section">
        <article>
            <h2>&#128161; Why StudySync?</h2>
            <p>
                Many students struggle to find the right study partner. StudySync solves this problem
                by making it easy to connect students with similar needs and schedules.
            </p>
        </article>

        <div class="card-container">
            <a href="Signup.aspx" class="card-link">
                <div class="card">
                    <h3>&#128101; Find Students</h3>
                    <p>Match with students in your course.</p>
                </div>
            </a>
            <a href="#schedule" class="card-link">
                <div class="card">
                    <h3>&#128336; Flexible Time</h3>
                    <p>Choose your available study time.</p>
                </div>
            </a>
            <a href="#study-mode" class="card-link">
                <div class="card">
                    <h3>&#128187; Online or In-Person</h3>
                    <p>Study anywhere you prefer.</p>
                </div>
            </a>
        </div>
    </section>

    <!-- ══ 7. Study Modes ══ -->
    <section id="study-mode" class="table-section">
        <h2>&#128218; Study Modes</h2>
        <div class="card-container">
            <div class="card">
                <h3>&#128187; Online Study</h3>
                <p>Study with students remotely using tools like Zoom or Microsoft Teams.</p>
            </div>
            <div class="card">
                <h3>&#127979; In-Person Study</h3>
                <p>Meet physically in the library or on campus for direct interaction.</p>
            </div>
        </div>
    </section>

    <!-- ══ 8. FAQ Accordion ══ -->
    <section class="accordion-section">
        <h2>&#10067; Frequently Asked Questions</h2>
        <p style="color:#666; margin-bottom:18px;">Click a question to expand the answer.</p>

        <div class="accordion-item">
            <button class="accordion-header">
                How do I find a study partner?
                <span class="accordion-icon">+</span>
            </button>
            <div class="accordion-body">
                <p>
                    Sign up or log in, then go to the <strong>Dashboard</strong> page. Create a study session
                    with your course, goal, and available time. Other students with the same course will see
                    your session and can join it. You can also join sessions created by others.
                </p>
            </div>
        </div>

        <div class="accordion-item">
            <button class="accordion-header">
                Is StudySync available for all courses?
                <span class="accordion-icon">+</span>
            </button>
            <div class="accordion-body">
                <p>
                    Yes! StudySync supports any course you type in. You can enter any course code such as
                    CPIS-358, MATH-101, or any other subject. The matching system will automatically find
                    students in the same course.
                </p>
            </div>
        </div>

        <div class="accordion-item">
            <button class="accordion-header">
                Can I study both online and in-person?
                <span class="accordion-icon">+</span>
            </button>
            <div class="accordion-body">
                <p>
                    Absolutely. When creating a study session, you can choose <strong>Online</strong> (using
                    tools like Zoom or Microsoft Teams) or <strong>In-Person</strong> to meet on campus.
                    You can create multiple sessions with different modes.
                </p>
            </div>
        </div>

        <div class="accordion-item">
            <button class="accordion-header">
                Is my personal data safe?
                <span class="accordion-icon">+</span>
            </button>
            <div class="accordion-body">
                <p>
                    StudySync stores your password securely using SHA-256 hashing. Your personal data is
                    only used within the platform to match you with study partners. Sessions and cookies
                    are used for login state management only.
                </p>
            </div>
        </div>

        <div class="accordion-item">
            <button class="accordion-header">
                How do I delete a study session I created?
                <span class="accordion-icon">+</span>
            </button>
            <div class="accordion-body">
                <p>
                    Go to the <strong>Dashboard</strong> page. Under <em>My Study Sessions</em>, find the
                    session you want to remove and click the <strong>Delete</strong> link. Only the session
                    creator can delete their own sessions.
                </p>
            </div>
        </div>
    </section>

</asp:Content>
