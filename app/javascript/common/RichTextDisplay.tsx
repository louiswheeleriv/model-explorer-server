import React from 'react';

type Props = {
  content: string;
  className?: string;
}

const RichTextDisplay = (props: Props) => {
  return (
    <div
      className={`prose prose-sm max-w-none  ${props.className || ''}`}
      dangerouslySetInnerHTML={{ __html: props.content || '<p>No notes</p>' }}
    />
  );
};

export default RichTextDisplay;
