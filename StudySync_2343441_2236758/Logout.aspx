<%@ Page Language="C#" AutoEventWireup="true" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        Session.Clear();
        Session.Abandon();

        // Clear only the preferred-course cookie.
        // IMPORTANT: Do NOT clear StudySyncStudentEmail.
        // The Login page uses it to load the last-used email after logout.
        string[] cookiesToClear = { "StudySyncPreferredCourse" };

        foreach (string cookieName in cookiesToClear)
        {
            if (Request.Cookies[cookieName] != null)
            {
                HttpCookie expired = new HttpCookie(cookieName);
                expired.Expires = DateTime.Now.AddDays(-1);
                expired.Path = "/";
                Response.Cookies.Add(expired);
            }
        }

        Response.Redirect("Login.aspx");
    }
</script>
