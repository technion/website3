import React from 'react';
import Layout from '../components/layout';
import { graphql } from 'gatsby';
import styled from 'styled-components';

const ContactTemplate = ({ data }) => {
  const { html, frontmatter } = data.markdownRemark;

  return (
    <Layout title={frontmatter.title}>
    <div>Unfinished Title
    <ContactCopy dangerouslySetInnerHTML={{ __html: html }} />
    </div>
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
