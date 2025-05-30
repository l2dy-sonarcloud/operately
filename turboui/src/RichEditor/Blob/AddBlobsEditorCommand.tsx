import { useUploadFile } from "../EditorContext";
import { UploadFileFn } from "../useEditor";

export function AddBlobsEditorCommand({ files, pos, view }: { files: File[] | FileList; pos: number; view: any }) {
  if (!view.editable) return false;

  const uploadFile = useUploadFile();

  Array.from(files).forEach(async (file) => {
    handleUpload(file, view, pos, uploadFile);
  });

  return true;
}

async function handleUpload(file: File, view: any, pos: any, uploadFile: UploadFileFn) {
  const tempId = generateUniqueId();

  // Step 1: Add a placeholder node before uploading the file.
  createNode(tempId, file, view, pos);

  // Step 2: Start the upload process and hook up progress updates.
  const promise = uploadFile(file, (progress) => {
    updateNodeAttrs(tempId, { progress: progress }, view);
  });

  // Step 3: Handle the result of the upload
  promise
    .then(({ id, url }) => {
      // On success, update the node with the new data.
      updateNodeAttrs(tempId, { id: id, src: url, status: "uploaded" }, view);
    })
    .catch(() => {
      // In case of an error, delete the node.
      deleteNode(tempId, view);
    });
}

function generateUniqueId() {
  return Date.now().toString(36) + Math.random().toString(36).substring(2);
}

function createNode(id: string, file: File, view: any, pos: any) {
  const { schema } = view.state;
  const blobSchema = schema.nodes.blob;

  let node = blobSchema.create({
    id: id,
    src: URL.createObjectURL(file),
    title: file.name,
    alt: file.name,
    status: "uploading",
    filetype: file.type,
    filesize: file.size,
  });

  const transaction = view.state.tr.insert(pos, node);
  view.dispatch(transaction);
}

function updateNodeAttrs(id: string, attrs: any, view: any) {
  const n = findNode(id, view.state.doc);
  if (!n.node) return;
  if (!n.pos) return;

  const transaction = view.state.tr;

  Object.keys(attrs).forEach((key) => {
    transaction.setNodeAttribute(n.pos, key, attrs[key]);
  });

  view.dispatch(transaction);
}

function deleteNode(id: string, view: any) {
  const n = findNode(id, view.state.doc);
  if (!n.node) return;
  if (!n.pos) return;

  const transaction = view.state.tr.delete(n.pos, n.pos + 1);
  view.dispatch(transaction);
}

function findNode(id: string, doc: any) {
  var result = { node: null, pos: null };

  doc.descendants((node: any, pos: any) => {
    if (node.attrs.id === id) {
      result.node = node;
      result.pos = pos;

      return false; // stop searching
    } else {
      return true;
    }
  });

  return result;
}
