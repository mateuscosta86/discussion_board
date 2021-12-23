// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// Bring in Phoenix channels client library:
import {
  Socket
} from "phoenix"

let socket = new Socket("/socket", {
  params: {
    token: window.userToken
  },
  logger: (kind, msg, data) => {
    console.log(`${kind}: ${msg}`, data)
  }
})

socket.connect()

const joinChannel = (topicId) => {
  let channel = socket.channel(`comments:${topicId}`, {})
  channel.join()
    .receive("ok", resp => {
      console.log(resp)
      renderComments(resp.comments)
    })
    .receive("error", resp => {
      console.log("Unable to join", resp)
    });

  channel.on(`comments:${topicId}:new`, event => renderComment(event.comment))

  document.querySelector('button')
    .addEventListener('click', () => {
      const content = document.querySelector('textarea').value;
      channel.push('comment:add', {
        content: content
      })
    });
};



function renderComments(comments) {
  const renderedComments = comments.map(comment => commentTemplate(comment));
  document.querySelector('.collection').innerHTML = renderedComments.join('');
};

function renderComment(comment) {
  const renderedComment = commentTemplate(comment);
  document.querySelector('.collection').innerHTML += renderedComment;
};

function commentTemplate(comment) {
  let email = comment.user ? comment.user.email : 'Anonymous';

  return `
    <li class="collection-item">
      ${comment.content}
      <div class="secondary-content">
        ${email}
      </div>
    </li>
  `;
};

window.joinChannel = joinChannel;
