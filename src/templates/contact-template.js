import React, { useEffect, useRef } from 'react';
import Layout from '../components/layout';
import { graphql } from 'gatsby';
import styled from 'styled-components';


const captcha = `
<iframe id="doom_captcha" src="https://vivirenremoto.github.io/doomcaptcha/captcha.html?version=17&countdown=on&enemies=4" style="width:300px;height:150px;border:2px black solid;"></iframe>

<script>
// Minor obfuscation
const getAddress = () => {
  const encoded = "d!!jaG5pb25AbG9sd2FyZS5uZXQ=";
  return atob(encoded.replace("!!", "GV"));

};

window.addEventListener('message', function(e) {
    if (e.origin.indexOf('vivirenremoto.github.io') > -1) {
        document.getElementById('doom_captcha').style.borderColor = 'black';
        const item = document.getElementById('emailoutput');
        item.innerHTML = "Contact address: " + getAddress();
    }
}, false);
</script>

`

const DangerouslySetHtmlContent = (props) => {
  //https://github.com/christo-pr/dangerously-set-html-content#readme
  const { html, ...rest } = props
  const divRef = useRef(null)

  useEffect(() => {
    if (!html) return

    const slotHtml = document.createRange().createContextualFragment(html) // Create a 'tiny' document and parse the html string
    divRef.current.innerHTML = '' // Clear the container
    divRef.current.appendChild(slotHtml) // Append the new content
  }, [html])


  return (
    <div {...rest} ref={divRef}></div>
  )
}


const ContactTemplate = ({ data }) => {
  const { html, frontmatter } = data.markdownRemark;

  return (
    <Layout title={frontmatter.title}>
    <ContactCopy dangerouslySetInnerHTML={{ __html: html }} />
    <DangerouslySetHtmlContent html={captcha} />
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
