<%@ Page Language="C#" MasterPageFile="Site.master" AutoEventWireup="true" %>

<asp:Content ID="Title" ContentPlaceHolderID="TitleContent" runat="server">StudySync - About Us</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <section class="about-section">
        <h2>&#128101; Who We Are</h2>
        <p>
            We are a group of students at King Abdulaziz University who created StudySync
            to help students find suitable study partners based on their course, goal, and free time.
        </p>

        <h2>&#127919; Our Mission</h2>
        <p>
            Our mission is to make studying easier, more organized, and more collaborative
            for university students.
        </p>

        <h2>&#127891; Team Members</h2>
        <ul>
            <li><strong>Student 1:</strong> Maitham Abbas &mdash; ID: 2343441</li>
            <li><strong>Student 2:</strong> Hashem Baroum &mdash; ID: 2236758</li>
        </ul>

        <h2>&#128187; Technologies Used</h2>
        <ul>
            <li>ASP.NET Web Forms (C#)</li>
            <li>SQL Server (LocalDB) with ADO.NET</li>
            <li>CSS3 with Dark Mode support</li>
            <li>JavaScript for client-side validation and interactivity</li>
            <li>Session and Cookie management</li>
        </ul>

        <p style="margin-top:20px;">
            <a href="Home.aspx">&#8592; Back to Home</a>
        </p>
    </section>
</asp:Content>
