<%@ Page Language="C#" MasterPageFile="Site.master" AutoEventWireup="true" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        DatabaseHelper.Initialize();

        if (!IsPostBack)
        {
            HttpCookie lastEmailCookie = Request.Cookies["StudySyncStudentEmail"];

            if (lastEmailCookie != null)
            {
                txtEmail.Text = lastEmailCookie.Value;
            }
        }
    }

    protected void btnResetPassword_Click(object sender, EventArgs e)
    {
        if (!Page.IsValid)
        {
            return;
        }

        if (txtNewPassword.Text.Trim().Length < 5)
        {
            lblResult.Text = "Password must be at least 5 characters.";
            lblResult.CssClass = "error-message";
            return;
        }

        if (txtNewPassword.Text.Trim() != txtConfirmPassword.Text.Trim())
        {
            lblResult.Text = "Passwords do not match.";
            lblResult.CssClass = "error-message";
            return;
        }

        bool updated = DatabaseHelper.ResetPassword(
            txtEmail.Text.Trim(),
            txtStudentId.Text.Trim(),
            txtNewPassword.Text.Trim()
        );

        if (updated)
        {
            HttpCookie emailCookie = new HttpCookie("StudySyncStudentEmail", txtEmail.Text.Trim());
            emailCookie.Expires = DateTime.Now.AddDays(7);
            emailCookie.Path = "/";
            Response.Cookies.Add(emailCookie);

            lblResult.Text = "Password changed successfully. You can login now.";
            lblResult.CssClass = "success-message";

            txtStudentId.Text = "";
            txtNewPassword.Text = "";
            txtConfirmPassword.Text = "";
        }
        else
        {
            lblResult.Text = "Email or Student ID is incorrect.";
            lblResult.CssClass = "error-message";
        }
    }
</script>

<asp:Content ID="Title" ContentPlaceHolderID="TitleContent" runat="server">
    StudySync - Forgot Password
</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <section class="form-container">
        <h2>Forgot Password</h2>

        <p class="note">
            Enter your registered email and student ID to change your password.
        </p>

        <label for="<%= txtEmail.ClientID %>">Email:</label>
        <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" CssClass="reset-email"
            placeholder="Enter your registered email"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvEmail" runat="server"
            ControlToValidate="txtEmail"
            ErrorMessage="Email is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= txtStudentId.ClientID %>">Student ID:</label>
        <asp:TextBox ID="txtStudentId" runat="server" CssClass="reset-student-id"
            placeholder="Enter your student ID"></asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvStudentId" runat="server"
            ControlToValidate="txtStudentId"
            ErrorMessage="Student ID is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <label for="<%= txtNewPassword.ClientID %>">New Password:</label>
        <asp:TextBox ID="txtNewPassword" runat="server"
            TextMode="Password"
            CssClass="reset-new-password password-field"
            placeholder="Enter new password"
            onkeyup="checkPasswordStrength(this.value)"
            oninput="checkPasswordStrength(this.value)">
        </asp:TextBox>

        <div class="password-strength-bar">
            <div id="pwStrengthFill" class="bar-fill"></div>
        </div>

        <div id="pwStrengthLabel" class="strength-label"></div>

        <asp:RequiredFieldValidator ID="rfvNewPassword" runat="server"
            ControlToValidate="txtNewPassword"
            ErrorMessage="New password is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <asp:RegularExpressionValidator ID="revNewPasswordLength" runat="server"
            ControlToValidate="txtNewPassword"
            ValidationExpression="^.{5,}$"
            ErrorMessage="Password must be at least 5 characters"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RegularExpressionValidator>

        <label for="<%= txtConfirmPassword.ClientID %>">Confirm New Password:</label>
        <asp:TextBox ID="txtConfirmPassword" runat="server"
            TextMode="Password"
            CssClass="reset-confirm-password confirm-password-field"
            placeholder="Confirm new password">
        </asp:TextBox>
        <asp:RequiredFieldValidator ID="rfvConfirmPassword" runat="server"
            ControlToValidate="txtConfirmPassword"
            ErrorMessage="Confirm password is required"
            CssClass="error-message"
            Display="Dynamic">
        </asp:RequiredFieldValidator>

        <span id="clientValidationResult" class="error-message"></span>

        <div class="button-row">
            <asp:Button ID="btnResetPassword" runat="server"
                Text="Change Password"
                OnClick="btnResetPassword_Click"
                OnClientClick="return validateResetPasswordClient();"
                CssClass="btn-primary" />
        </div>

        <asp:Label ID="lblResult" runat="server"></asp:Label>

        <p style="margin-top:15px; color:#555;">
            Remember your password? <a href="Login.aspx">Back to Login</a>.
        </p>
    </section>
</asp:Content>
