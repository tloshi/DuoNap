import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const NOW = Date.now();
const DAY = 24 * 60 * 60 * 1000;
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-duonap',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => env.cleanup());

beforeEach(async () => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid).firestore();

function family(members, overrides = {}) {
  return {
    members,
    joinCode: 'ABC234',
    joinCodeExpiresAtMs: NOW + DAY,
    babies: [{ id: 'first', name: 'A' }, { id: 'second', name: 'B' }],
    settings: { plannedBedtimeMinutes: 1275, usualWakeMinutes: 480 },
    shift: null,
    updatedAtMs: NOW,
    ...overrides,
  };
}

function session(uid, overrides = {}) {
  return { babyId: 'first', kind: 'nap', startMs: 1, endMs: 2, updatedAtMs: 10, updatedBy: uid, ...overrides };
}

async function seed(entries) {
  await env.withSecurityRulesDisabled(async (context) => {
    for (const [path, value] of Object.entries(entries)) {
      await setDoc(doc(context.firestore(), path), value);
    }
  });
}

test('a member reads the family; an outsider and a stranger cannot', async () => {
  await seed({ 'families/f1': family(['alice']) });
  await assertSucceeds(getDoc(doc(db('alice'), 'families/f1')));
  await assertFails(getDoc(doc(db('mallory'), 'families/f1')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'families/f1')));
});

test('a family is created with yourself as the only member, with its code', async () => {
  const alice = db('alice');
  const batch = writeBatch(alice);
  batch.set(doc(alice, 'families/f1'), family(['alice']));
  batch.set(doc(alice, 'joinCodes/ABC234'), { familyId: 'f1', expiresAtMs: NOW + DAY });
  await assertSucceeds(batch.commit());
  await assertFails(setDoc(doc(alice, 'families/f2'), family(['alice', 'bob'])));
  await assertFails(setDoc(doc(alice, 'families/f3'), family(['bob'])));
});

test('joining with the current code adds only yourself', async () => {
  await seed({ 'families/f1': family(['alice']) });
  await assertSucceeds(
    updateDoc(doc(db('bob'), 'families/f1'), { members: arrayUnion('bob'), joinedWith: 'ABC234' }),
  );
  await assertFails(
    updateDoc(doc(db('carol'), 'families/f1'), { members: arrayUnion('carol', 'dave'), joinedWith: 'ABC234' }),
  );
});

test('a wrong or expired code does not let anyone in', async () => {
  await seed({ 'families/f1': family(['alice']), 'families/f2': family(['alice'], { joinCodeExpiresAtMs: NOW - 1000 }) });
  await assertFails(updateDoc(doc(db('bob'), 'families/f1'), { members: arrayUnion('bob'), joinedWith: 'ZZZ999' }));
  await assertFails(updateDoc(doc(db('bob'), 'families/f2'), { members: arrayUnion('bob'), joinedWith: 'ABC234' }));
  await assertFails(updateDoc(doc(db('bob'), 'families/f1'), { members: arrayUnion('bob'), joinedWith: 'ABC234', joinCode: 'ZZZ999' }));
});

test('a member changes settings but not who belongs to the family', async () => {
  await seed({ 'families/f1': family(['alice', 'bob']) });
  await assertSucceeds(updateDoc(doc(db('alice'), 'families/f1'), { 'settings.plannedBedtimeMinutes': 1200, updatedAtMs: NOW + 1 }));
  await assertFails(updateDoc(doc(db('alice'), 'families/f1'), { members: ['alice'] }));
  await assertFails(deleteDoc(doc(db('alice'), 'families/f1')));
});

test('members write valid sessions; outsiders cannot read or write them', async () => {
  await seed({ 'families/f1': family(['alice']) });
  await assertSucceeds(setDoc(doc(db('alice'), 'families/f1/sessions/s1'), session('alice')));
  await assertSucceeds(getDocs(collection(db('alice'), 'families/f1/sessions')));
  await assertFails(getDocs(collection(db('mallory'), 'families/f1/sessions')));
  await assertFails(setDoc(doc(db('mallory'), 'families/f1/sessions/s2'), session('mallory')));
});

test('a session is stamped by its writer and uses known values', async () => {
  await seed({ 'families/f1': family(['alice', 'bob']) });
  const sessions = (uid) => doc(db(uid), 'families/f1/sessions/s1');
  await assertFails(setDoc(sessions('alice'), session('bob')));
  await assertFails(setDoc(sessions('alice'), session('alice', { babyId: 'third' })));
  await assertFails(setDoc(sessions('alice'), session('alice', { kind: 'feeding' })));
  await assertFails(setDoc(sessions('alice'), session('alice', { name: 'Elena' })));
  await assertSucceeds(setDoc(sessions('alice'), session('alice', { endMs: null })));
});

test('an older write cannot replace a newer session', async () => {
  await seed({ 'families/f1': family(['alice', 'bob']), 'families/f1/sessions/s1': session('alice', { updatedAtMs: 50 }) });
  await assertFails(setDoc(doc(db('bob'), 'families/f1/sessions/s1'), session('bob', { updatedAtMs: 40 })));
  await assertSucceeds(setDoc(doc(db('bob'), 'families/f1/sessions/s1'), session('bob', { updatedAtMs: 60 })));
});

test('a join code is looked up by its code, never listed or taken over', async () => {
  await seed({
    'families/f1': family(['alice']),
    'families/f9': family(['mallory']),
    'joinCodes/ABC234': { familyId: 'f1', expiresAtMs: NOW + DAY },
  });
  await assertSucceeds(getDoc(doc(db('bob'), 'joinCodes/ABC234')));
  await assertFails(getDocs(collection(db('bob'), 'joinCodes')));
  await assertFails(setDoc(doc(db('mallory'), 'joinCodes/ABC234'), { familyId: 'f9', expiresAtMs: NOW + DAY }));
  await assertFails(setDoc(doc(db('mallory'), 'joinCodes/NEW111'), { familyId: 'f1', expiresAtMs: NOW + DAY }));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'joinCodes/ABC234')));
});
