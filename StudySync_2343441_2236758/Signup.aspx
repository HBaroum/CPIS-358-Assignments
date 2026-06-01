<%@ Page Language="C#" MasterPageFile="Site.master" AutoEventWireup="true" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        DatabaseHelper.Initialize();
    }

    protected void btnSignup_Click(object sender, EventArgs e)
    {
        if (!Page.IsValid)
        {
            return;
        }

        if (txtPassword.Text.Trim().Length < 5)
        {
            lblResult.Text = "Password must be at least 5 characters.";
            lblResult.CssClass = "error-message";
            return;
        }

        if (txtPassword.Text.Trim() != txtConfirmPassword.Text.Trim())
        {
            lblResult.Text = "Passwords do not match.";
            lblResult.CssClass = "error-message";
            return;
        }

        try
        {
            int userId = DatabaseHelper.AddUser(
                txtFullName.Text.Trim(),
                txtStudentId.Text.Trim(),
                txtEmail.Text.Trim(),
                txtCourse.Text.Trim(),
                ddlGoal.SelectedValue,
                txtTime.Text.Trim(),
                ddlStudyLevel.SelectedValue,
                rblMode.SelectedValue,
                txtPassword.Text.Trim()
            );

            Session["UserID"] = userId;
            Session["FullName"] = txtFullName.Text.Trim();
            Session["Email"] = txtEmail.Text.Trim();

            HttpCookie courseCookie = new HttpCookie("StudySyncPreferredCourse", txtCourse.Text.Trim());
            courseCookie.Expires = DateTime.Now.AddDays(14);
            courseCookie.Path = "/";
            Response.Cookies.Add(courseCookie);

            HttpCookie emailCookie = new HttpCookie("StudySyncStudentEmail", txtEmail.Text.Trim());
            emailCookie.Expires = DateTime.Now.AddDays(7);
            emailCookie.Path = "/";
            Response.Cookies.Add(emailCookie);

            Response.Redirect("Dashboard.aspx?created=1");
        }
        catch (System.Data.SqlClient.SqlException ex)
        {
            if (ex.Number == 2601 || ex.Number == 2627)
            {
                lblResult.Text = "The email already exists.";
            }
            else
            {
                lblResult.Text = "Could not create account. Please try again.";
            }

            lblResult.CssClass = "error-message";
        }
        catch (Exception)
        {
            lblResult.Text = "Could not create account. Please try again.";
            lblResult.CssClass = "error-message";
        }
    }
</script>

<asp:Content ID="Title" ContentPlaceHolderID="TitleContent" runat="server">
    StudySync - Sign Up
</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <section class="form-container">
        <h2>Create Account</h2>
        <asp:ValidationSummary ID="vsSignup" runat="server"
    CssClass="error-message"
    HeaderText="Please fix the following errors:"
    DisplayMode="BulletList" />

        <label for="<%= txtFullName.ClientID %>">Full Name:</label>
        <asp:TextBox ID="txtFullName" runat="server" placeholder="Enter your full name"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvFullName" runat="server"
            ControlToValidate="txtFullName"
            ErrorMessage="Full name is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= txtStudentId.ClientID %>">Student ID:</label>
        <asp:TextBox ID="txtStudentId" runat="server" placeholder="Enter your student ID"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvStudentId" runat="server"
            ControlToValidate="txtStudentId"
            ErrorMessage="Student ID is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= txtEmail.ClientID %>">Email:</label>
        <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" placeholder="Enter your email"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvEmail" runat="server"
            ControlToValidate="txtEmail"
            ErrorMessage="Email is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

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

        <label for="<%= ddlStudyLevel.ClientID %>">Study Level:</label>
        <asp:DropDownList ID="ddlStudyLevel" runat="server" CssClass="study-level-field">
            <asp:ListItem Value="">Select study level</asp:ListItem>
            <asp:ListItem>Beginner</asp:ListItem>
            <asp:ListItem>Intermediate</asp:ListItem>
            <asp:ListItem>Advanced</asp:ListItem>
        </asp:DropDownList>
        <asp:RequiredFieldValidator ID="rfvStudyLevel" runat="server"
            ControlToValidate="ddlStudyLevel"
            InitialValue=""
            ErrorMessage="Study level is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label>Preferred Mode:</label>
        <asp:RadioButtonList ID="rblMode" runat="server" RepeatDirection="Horizontal" CssClass="radio-group">
            <asp:ListItem>Online</asp:ListItem>
            <asp:ListItem>In-Person</asp:ListItem>
        </asp:RadioButtonList>
        <asp:RequiredFieldValidator ID="rfvMode" runat="server"
            ControlToValidate="rblMode"
            ErrorMessage="Preferred mode is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= txtPassword.ClientID %>">Password:</label>
        <asp:TextBox ID="txtPassword" runat="server"
            TextMode="Password"
            CssClass="password-field"
            placeholder="Enter password"
            onkeyup="checkPasswordStrength(this.value)"
            oninput="checkPasswordStrength(this.value)">
        </asp:TextBox>

        <div class="password-strength-bar">
            <div id="pwStrengthFill" class="bar-fill"></div>
        </div>

        <div id="pwStrengthLabel" class="strength-label"></div>

        <asp:RequiredFieldValidator ID="rfvPassword" runat="server"
            ControlToValidate="txtPassword"
            ErrorMessage="Password is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <asp:RegularExpressionValidator ID="revPasswordLength" runat="server"
            ControlToValidate="txtPassword"
            ValidationExpression="^.{5,}$"
            ErrorMessage="Password must be at least 5 characters"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RegularExpressionValidator>

        <label for="<%= txtConfirmPassword.ClientID %>">Confirm Password:</label>
        <asp:TextBox ID="txtConfirmPassword" runat="server"
            TextMode="Password"
            CssClass="confirm-password-field"
            placeholder="Confirm password">
        </asp:TextBox>

        <asp:RequiredFieldValidator ID="rfvConfirm" runat="server"
            ControlToValidate="txtConfirmPassword"
            ErrorMessage="Confirm password is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <span id="clientValidationResult" class="error-message"></span>

        <asp:Button ID="btnSignup" runat="server"
            Text="Sign Up"
            OnClick="btnSignup_Click"
            OnClientClick="return validateSignupClient();" />

        <asp:Label ID="lblResult" runat="server"></asp:Label>
    </section>
</asp:Content>
