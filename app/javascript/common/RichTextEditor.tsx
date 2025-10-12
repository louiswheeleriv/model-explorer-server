import React from 'react';
import Editor, { BtnBold, BtnBulletList, BtnItalic, BtnLink, BtnNumberedList, BtnStrikeThrough, BtnStyles, BtnUnderline, Separator, Toolbar } from 'react-simple-wysiwyg';

type Props = {
  value: string;
  onChange: (content: string) => void;
  className?: string;
}

const RichTextEditor = (props: Props) => {
  return (
    <div className={props.className}>
      <Editor
        value={props.value}
        onChange={(e) => props.onChange(e.target.value)}
        className='prose prose-sm w-full min-h-[200px] p-2'
      >
        <Toolbar>
          <BtnBold />
          <BtnItalic />
          <BtnUnderline />
          <BtnStrikeThrough />
          <Separator />
          <BtnNumberedList />
          <BtnBulletList />
        </Toolbar>
      </Editor>
    </div>
  );
};

export default RichTextEditor;
