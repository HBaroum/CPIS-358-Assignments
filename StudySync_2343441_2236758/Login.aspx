<%@ Page Language="C#" MasterPageFile="Site.master" AutoEventWireup="true" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        DatabaseHelper.Initialize();

        if (!IsPostBack)
        {
            ClearOldEmailCookie();

            HttpCookie lastEmailCookie = Request.Cookies["StudySyncStudentEmail"];

            if (lastEmailCookie != null)
            {
                txtEmail.Text      = lastEmailCookie.Value;
                lblCookieMessage.Text = "Cookie found: last-used student email was loaded automatically (" + lastEmailCookie.Value + "). Password is not saved for security.";
            }
            else
            {
                lblCookieMessage.Text = "No saved-email cookie found. Login once to set it.";
            }
        }
    }

    private void ClearOldEmailCookie()
    {
        if (Request.Cookies["StudySyncLastEmail"] != null)
        {
            HttpCookie oldCookie = new HttpCookie("StudySyncLastEmail");
            oldCookie.Expires = DateTime.Now.AddDays(-1);
            Response.Cookies.Add(oldCookie);
        }
    }

    protected void btnLogin_Click(object sender, EventArgs e)
    {
        if (!Page.IsValid) return;

        StudyUser user = DatabaseHelper.ValidateUser(
            txtEmail.Text.Trim(),
            txtPassword.Text.Trim()
        );

        if (user != null)
        {
            Session["UserID"]   = user.UserId;
            Session["FullName"] = user.FullName;
            Session["Email"]    = user.Email;

            HttpCookie emailCookie = new HttpCookie("StudySyncStudentEmail", user.Email);
            emailCookie.Expires = DateTime.Now.AddDays(7);
            emailCookie.Path    = "/";
            Response.Cookies.Add(emailCookie);

            Response.Redirect("Dashboard.aspx");
        }
        else
        {
            lblResult.Text     = "Invalid email or password. Please try again.";
            lblResult.CssClass = "error-message";
        }
    }
</script>

<asp:Content ID="Title" ContentPlaceHolderID="TitleContent" runat="server">
    StudySync - Login
</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <section class="form-container">
        <h2>Login</h2>
        <p class="note">Please login using your registered student account.</p>

        <asp:Label ID="lblCookieMessage" runat="server" CssClass="success-message"></asp:Label>

        <label for="<%= txtEmail.ClientID %>">Email:</label>
        <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" CssClass="login-email"
            placeholder="Enter your email"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvEmail" runat="server"
            ControlToValidate="txtEmail"
            ErrorMessage="Email is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= txtPassword.ClientID %>">Password:</label>
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="login-password"
            placeholder="Enter your password"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvPassword" runat="server"
            ControlToValidate="txtPassword"
            ErrorMessage="Password is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <span id="clientValidationResult" class="error-message"></span>

        <div class="button-row">
            <asp:Button ID="btnLogin" runat="server"
                Text="Login"
                OnClick="btnLogin_Click"
                OnClientClick="return validateLoginClient();"
                CssClass="btn-primary" />
        </div>

        <asp:Label ID="lblResult" runat="server"></asp:Label>

        <p style="margin-top:15px; color:#555;">
            Don't have an account? <a href="Signup.aspx">Sign up here</a>.
        </p>

        <p style="margin-top:8px; color:#555;">
            Forgot your password? <a href="ForgotPassword.aspx">Reset it here</a>.
        </p>
    </section>
</asp:Content>
