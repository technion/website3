import React from "react";
import Layout from "../components/layout";
import DoomCaptcha from "../components/captchaevent";
import { graphql } from "gatsby";
import styled from "styled-components";

const ContactTemplate = ({ data }) => {
  const { html, frontmatter } = data.markdownRemark;
  const frameStyle = {
    width: "300px",
    height: "150px",
    border: "2px black solid",
  };

  const isSSR = typeof window === "undefined";

  return (
    <Layout title={frontmatter.title}>
      <ContactCopy dangerouslySetInnerHTML={{ __html: html }} />
      <iframe
        id="doom_captcha"
        title="Doom Captcha"
        src="https://vivirenremoto.github.io/doomcaptcha/captcha.html?version=17&countdown=on&enemies=4"
        style={frameStyle}
        sandbox="allow-same-origin allow-popups allow-scripts"
      ></iframe>
      {!isSSR && (
        <React.Suspense fallback={<div />}>
          <DoomCaptcha />
        </React.Suspense>
      )}
      <DoomCaptcha />
      <div id="emailoutput"></div>
    </Layout>
  );
};

export default ContactTemplate;

const ContactCopy = styled.div`
  max-width: 45ch;
  & p {
    font-size: var(--size-400);
  }
`;

export const pageQuery = graphql`
  query($slug: String!) {
    markdownRemark(fields: { slug: { eq: $slug } }) {
      html
      frontmatter {
        title
      }
    }
  }
`;
