#!/usr/bin/env python3
"""Offline registry safety regression tests."""
import importlib.util
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('cleanup', Path(__file__).resolve().parents[1] / 'scripts/cleanup-registries.py')
cleanup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cleanup)


class CleanupTests(unittest.TestCase):
    def test_retention(self):
        self.assertEqual(cleanup.keep_tags(['pr-1', '153.5.0esr-bb11', '153.4.0esr-bb10', '140.5.0esr-bb14'], 3, {'140.5.0esr-bb14'}),
                         {'latest', '153.5.0esr-bb11', '153.4.0esr-bb10'})

    def run_cleanup(self, apply=False, fail=False):
        deleted = []
        def version(identifier, tags):
            return {'id': identifier, 'name': f'sha256:{identifier}', 'created_at': str(identifier), 'metadata': {'container': {'tags': tags}}}
        def request(url, token=None, method='GET', **kwargs):
            if method == 'DELETE':
                deleted.append(url)
                return None, {}
            if 'users/login' in url:
                return {'token': 'fake'}, {}
            if 'hub.docker.com' in url:
                return {'results': [{'name': name, 'last_updated': str(i)} for i, name in enumerate(['pr-1', '153.5.0esr-bb11', 'latest'])], 'next': None}, {}
            if url.endswith('/users/test'):
                return {'type': 'User'}, {}
            if '/versions' in url:
                if 'page=2' in url:
                    return [version(1, ['pr-1'])], {}
                return [version(5, ['latest', '153.5.0esr-bb11']), version(4, []), version(3, ['pr-child'])], {'Link': '<https://api.github.com/users/test/packages/container/image/versions?page=2>; rel="next"'}
            if '/token?' in url:
                return {'token': 'fake'}, {}
            if '/manifests/' in url:
                if fail:
                    raise ValueError('cannot inspect manifest')
                return {'manifests': [{'digest': 'sha256:3'}]} if url.endswith('sha256:5') else {}, {}
            raise AssertionError(url)
        env = {'OWNER': 'test', 'IMAGE_NAME': 'image', 'DOCKER_HUB_USERNAME': 'test', 'DOCKER_HUB_TOKEN': 'fake', 'GH_TOKEN': 'fake', 'KEEP_VERSION_TAGS': '3'}
        with patch.dict(os.environ, env, clear=True), patch.object(cleanup, 'request', request), patch.object(sys, 'argv', ['cleanup'] + (['--apply'] if apply else [])):
            if fail:
                with self.assertRaises(ValueError):
                    cleanup.main()
            else:
                cleanup.main()
        return deleted

    def test_dry_run(self):
        self.assertEqual(self.run_cleanup(), [])

    def test_protect_children_and_untagged(self):
        deleted = self.run_cleanup(apply=True)
        self.assertEqual(len(deleted), 2)
        self.assertTrue(any(url.endswith('/versions/1') for url in deleted))
        self.assertTrue(any(url.endswith('/tags/pr-1/') for url in deleted))

    def test_fail_before_any_deletion(self):
        self.assertEqual(self.run_cleanup(apply=True, fail=True), [])


if __name__ == '__main__':
    unittest.main()
