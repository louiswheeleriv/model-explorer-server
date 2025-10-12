export type UserModelStatus = 'unassembled' | 'assembled' | 'in_progress' | 'finished';

export type QuantityByStatus = {
  unassembled: number;
  assembled: number;
  in_progress: number;
  finished: number;
}

export type GameSystem = {
  id: number;
  name: string;
}

export type Faction = {
  id: number;
  game_system_id: number;
  name: string;
};

export type Model = {
  id: number;
  faction_id: number;
  name: string;
};

export type UserModel = {
  id: number;
  user_id: number;
  model_id: number;
  user_faction_id: number;
  user_model_group_id: number;
  name: string;
  model_name?: string;
  notes: string;
  num_images?: number;
  qty_unassembled: number;
  qty_assembled: number;
  qty_in_progress: number;
  qty_finished: number;
};

export type UserModelGroup = {
  id: number;
  user_id: number;
  user_faction_id: number;
  name: string;
  sort_index?: number;
};

export type User = {
  id: number;
  username: string;
  display_name: string;
  email: string;
  bio: string;
  profile_picture_url?: string;
  model_num_by_status?: QuantityByStatus;
}

export type UserFaction = {
  id: number;
  user_id: number;
  faction_id: number;
  name: string;
  notes: string;
  faction_name?: string;
}

export type UserImage = {
  id: number;
  user_id: number;
  url: string;
}

export type UserImageAssociation = {
  id: number;
  user_id: number;
  user_image_id: number;
  user_faction_id?: number;
  user_model_id?: number;
  post_id?: number;
  sort_index: number;
}

export type Post = {
  id: number;
  user_id: number;
  body: string;
  created_at: string;
  updated_at: string;
}

export type PostComment = {
  id: number;
  post_id: number;
  user_id: number;
  user_username: string;
  user_display_name?: string;
  user_profile_picture_url?: string;
  is_followed_by_current_user: boolean;
  body: string;
  post_comment_reactions: PostReaction[];
  created_at: string;
  updated_at: string;
}

export type PostReaction = {
  id: number;
  post_id: number;
  user_id: number;
  user_username: string;
  user_display_name?: string;
  user_profile_picture_url?: string;
  reaction: string;
}

export type UserModelPost = {
  id: number;
  user_id: number;
  user_model_id: number;
  post_id: number;
}

export type UserData = {
  user: User;
  model_num_by_status?: QuantityByStatus;
}

export type PostData = {
  post: Post;
  user: User;
  profile_picture: UserImage;
  is_followed_by_current_user: boolean;
  post_comments: PostComment[];
  post_reactions: PostReaction[];
  user_models: UserModel[];
  user_images: UserImage[];
}