import React from 'react';
import Layout from '../components/layout';
import { graphql } from 'gatsby';
import { useForm } from 'react-hook-form';
import styled from 'styled-components';

const ContactTemplate = ({ data }) => {
  const { html, frontmatter } = data.markdownRemark;

  return (
    <Layout title={frontmatter.title}  dangerouslySetInnerHTML={{ __html: html }}>
    </Layout>
  );
};

export default ContactTemplate;

